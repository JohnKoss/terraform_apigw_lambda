output "id" {
  description = "ARN of the lambda function"
  value = aws_lambda_function.this.id
}
output "arn" {
  description = "ARN of the lambda function"
  value = aws_lambda_function.this.arn
}
