output "id" {
  description = "ARN of the lambda function"
  value = module.ws_labs.id
}
output "arn" {
  description = "ARN of the lambda function"
  value = module.ws_labs.arn
}
output "invoke_arn" {
  description = "Invoke ARN of the lambda function"
  value = module.ws_labs.invoke_arn
}
output "lanbda_role_id" {
  description = "The role of the lambda function."
  value = module.ws_labs.role.id
}
