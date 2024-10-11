variable "lambda" {
  type = object({
    name             = string
    path             = string
    description      = optional(string)
    timeout          = optional(number)
    other_args       = optional(string, "")
    managed_policies = optional(list(string))
    inline_policies = optional(list(object({
      name   = string
      policy = string
    })))
    env_vars = optional(map(any))
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
variable "arch" {
  type    = string
  default = "arm64"
  validation {
    condition     = contains(["x86_64", "arm64"], var.arch)
    error_message = "The value for 'arch' must be either 'x86_64' or 'arm64'."
  }
}
variable "authorizer_id" {
  type    = string
  default = null
}

variable "authorizer_type" {
  type    = string
  default = null
}
