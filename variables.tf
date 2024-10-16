variable "lambda" {
  type = object({
    name             = string
    path             = string
    arch             = optional(string, "arm64")
    description      = optional(string)
    timeout          = optional(number,5)
    memory_size      = optional(number,128)
    other_args       = optional(string, "")
    docker_host      = optional(string, "tcp://127.0.0.1:2375")
    managed_policies = optional(list(string))
    inline_policies = optional(list(object({
      name   = string
      policy = string
    })))
    env_vars = optional(map(any))
  })
  validation {
    condition     = contains(["arm64", "x86_64"], var.lambda.arch)
    error_message = "The architecture must be either 'arm64' or 'x86_64'."
  }
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
