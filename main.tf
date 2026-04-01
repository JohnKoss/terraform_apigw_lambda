#####
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
}

####################### APIGateway stuff  ###############################
resource "aws_apigatewayv2_integration" "lambda" {
  count                  = length(var.apigateway.routes)
  api_id                 = var.apigateway.id
  payload_format_version = "2.0"
  integration_uri        = module.terraform_lambda.invoke_arn
  integration_type       = "AWS_PROXY"
  #integration_method     = var.apigateway.routes[count.index].method
  integration_method     = "POST"  # always POST for Lambda proxy
}

//// apigateway routes
resource "aws_apigatewayv2_route" "launch_path" {
  count              = length(var.apigateway.routes)
  api_id             = var.apigateway.id
  route_key          = "${var.apigateway.routes[count.index].method} ${var.apigateway.routes[count.index].path}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda[count.index].id}"
  authorization_type = var.authorizer_type
  authorizer_id      = var.authorizer_id

  depends_on = [aws_apigatewayv2_integration.lambda]
}

// Permissions for apigateway to invoke the lambda functions
resource "aws_lambda_permission" "lambda" {
  depends_on = [
    module.terraform_lambda
  ]

  count         = length(var.apigateway.routes)
  statement_id  = "AllowExecutionFromAPIGateway-${var.apigateway.routes[count.index].method}-${count.index}"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = var.lambda.name
  source_arn    = "arn:aws:execute-api:${local.region}:${local.account_id}:${var.apigateway.id}/*/${var.apigateway.routes[count.index].method}${var.apigateway.routes[count.index].path}"
}

####################### Lambda stuff  ###############################
//////////
module "terraform_lambda" {
  source = "github.com/JohnKoss/terraform_lambda"

  path        = var.lambda.path
  name        = var.lambda.name
  desc        = var.lambda.description
  timeout     = var.lambda.timeout
  memory_size = var.lambda.memory_size
  other_args  = var.lambda.other_args
  arch        = var.lambda.arch
  docker_host = var.lambda.docker_host

  env_vars = var.lambda.env_vars

  managed_policies = var.lambda.managed_policies
  inline_policies  = var.lambda.inline_policies
}
