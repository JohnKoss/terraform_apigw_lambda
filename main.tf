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
  integration_uri        = aws_lambda_function.this.arn
  integration_type       = "AWS_PROXY"
  integration_method     = var.apigateway.routes[count.index].method
}


//// apigateway routes
resource "aws_apigatewayv2_route" "launch_path" {
  count              = length(var.apigateway.routes)
  api_id             = var.apigateway.id
  route_key          = "${var.apigateway.routes[count.index].method} ${var.apigateway.routes[count.index].path}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda[count.index].id}"
  authorization_type = var.authorizer_type == null ? null : var.authorizer_type
  authorizer_id      = var.authorizer_id == null ? null : var.authorizer_id
}

// Permissions for apigateway to invoke the lambda functions
resource "aws_lambda_permission" "lambda" {
  count         = length(var.apigateway.routes)
  statement_id  = "AllowExecutionFromAPIGateway-${var.apigateway.routes[count.index].method}-${count.index}"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = var.lambda.name
  source_arn    = "arn:aws:execute-api:${local.region}:${local.account_id}:${var.apigateway.id}/*/${var.apigateway.routes[count.index].method}${var.apigateway.routes[count.index].path}"
}

####################### Lambda stuff  ###############################

resource "null_resource" "lambda_build" {

  // Compile the Lambda function(s) when ever any of the *.go file changes
  triggers = {

    // For this trigger, terraform will set to false if not exists.
    archive_exists = fileexists("${var.lambda.path}/archive/${var.lambda.name}")

    // Check the hash of all file to see if there are any changes, which will cause an upload.
    dir_sha1 = sha1(join("", [for f in fileset("${var.lambda.path}", "*.go") : filesha1("${var.lambda.path}/${f}")]))
  }

  provisioner "local-exec" {
    command     = "go build -ldflags=-s -ldflags=-w -o archive/${var.lambda.name} ."
    working_dir = var.lambda.path
    environment = {
      GO111MODULE = "on"
      GOOS        = "linux"
    }
  }
}

// Zip and upload the complied lambda to AWS Lambda...
data "archive_file" "lambda_archive" {
  depends_on = [null_resource.lambda_build]

  type             = "zip"
  source_file      = "${var.lambda.path}/archive/${var.lambda.name}"
  output_path      = "${var.lambda.path}/archive/${var.lambda.name}.zip"
  output_file_mode = "0777"
}

////////////////
// https://github.com/hashicorp/terraform-provider-aws/issues/1110
locals {
  environment_map = var.lambda.env_vars[*]
}

resource "aws_lambda_function" "this" {
  description   = var.lambda.description
  filename      = "${var.lambda.path}/archive/${var.lambda.name}.zip"
  function_name = var.lambda.name
  role          = aws_iam_role.iam_lambda_role.arn
  handler       = var.lambda.name

  // https://devcoops.com/terraform-aws-lambda-data-archive-file/
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256

  runtime = "go1.x"

  dynamic "environment" {
    for_each = local.environment_map
    content {
      variables = environment.value
    }
  }
}

resource "aws_iam_role" "iam_lambda_role" {
  name = "_clearbyte_${var.lambda.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

// Add the "AWSLambdaBasicExecutionRole" policy and any additional for the lambda.
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  for_each = toset(concat(["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"], var.lambda.policies))

  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "lambda_log" {
  name = "/aws/lambda/${aws_lambda_function.this.function_name}"

  retention_in_days = 1
}
