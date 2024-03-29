variable "lambda" {
  type = object({
    name        = string
    path        = string
    description = optional(string)
    timeout     = optional(number)
    other_args  = optional(string, "")
    policies    = optional(list(string))
    env_vars    = optional(map(any))
  })
}

variable "apigateway" {
  type = object({
    id = string
    routes = list(object({
      method = string
      path   = string
    }))
  })
}

variable "authorizer_id" {
  type    = string
  default = null
}

variable "authorizer_type" {
  type    = string
  default = null
}
