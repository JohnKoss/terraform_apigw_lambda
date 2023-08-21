output "id" {
  description = "ARN of the lambda function"
  value = aws_lambda_function.this.id
}
output "arn" {
  description = "ARN of the lambda function"
  value = aws_lambda_function.this.arn
}
output "invoke_arn" {
  description = "Invoke ARN of the lambda function"
  value = aws_lambda_function.this.invoke_arn
}
output "lanbda_role_id" {
  description = "The role of the lambda function."
  value = aws_iam_role.iam_lambda_role.id
}
