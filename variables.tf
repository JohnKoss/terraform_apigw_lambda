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
    routes = list(object({
      method        = string
      path          = string
    }))
  })
}

variable "authorizer_id" {
    type = string
    default = null
}

variable "authorizer_type" {
    type = string
    default = null
}