output "id" {
  description = "ARN of the lambda function"
  value = module.terraform_lambda.id
}
output "arn" {
  description = "ARN of the lambda function"
  value = module.terraform_lambda.arn
}
output "invoke_arn" {
  description = "Invoke ARN of the lambda function"
  value = module.terraform_lambda.invoke_arn
}
output "lambda_role_id" {
  description = "The role of the lambda function."
  value = module.terraform_lambda.lambda_role_id
}
output "api_gateway_integration_id" {
  description = "The ID of the API Gateway integration."
  value = aws_apigatewayv2_integration.lambda[0].id
}