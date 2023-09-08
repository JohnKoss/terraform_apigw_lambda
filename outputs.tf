output "id" {
  description = "ARN of the lambda function"
  value = aws_lambda_function.image.id
}
output "arn" {
  description = "ARN of the lambda function"
  value = aws_lambda_function.image.arn
}
output "invoke_arn" {
  description = "Invoke ARN of the lambda function"
  value = aws_lambda_function.image.invoke_arn
}
output "lanbda_role_id" {
  description = "The role of the lambda function."
  value = aws_iam_role.iam_for_lambda.id
}
