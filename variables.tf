variable "lambda" {
  type = object({
    name        = string
    path        = string
    description = string
    policies    = list(string)
    env_vars    = map(any)
  })
}

variable "apigateway" {
  type = object({
    id  = string
    arn = string
    routes = list(object({
      method = string
      path   = string
    }))
  })
}
