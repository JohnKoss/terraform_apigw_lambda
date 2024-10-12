#####
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
}

####################### APIGateway stuff  ###############################
resource "aws_apigatewayv2_integration" "lambda" {
  count                  = length(var.apigateway.routes)
  api_id                 = var.apigateway.id
  payload_format_version = "2.0"
  //integration_uri        = aws_lambda_function.image.arn
  integration_uri    = module.terraform_lambda.arn
  integration_type   = "AWS_PROXY"
  integration_method = var.apigateway.routes[count.index].method
}

//// apigateway routes
resource "aws_apigatewayv2_route" "launch_path" {
  count     = length(var.apigateway.routes)
  api_id    = var.apigateway.id
  route_key = "${var.apigateway.routes[count.index].method} ${var.apigateway.routes[count.index].path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[count.index].id}"
  //authorization_type = var.authorizer_type == null ? null : var.authorizer_type
  //authorizer_id      = var.authorizer_id == null ? null : var.authorizer_id
  authorization_type = var.authorizer_type
  authorizer_id      = var.authorizer_id

}

// Permissions for apigateway to invoke the lambda functions
resource "aws_lambda_permission" "lambda" {
  count         = length(var.apigateway.routes)
  statement_id  = "AllowExecutionFromAPIGateway-${var.apigateway.routes[count.index].method}-${count.index}"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = var.lambda.name
  source_arn    = "arn:aws:execute-api:${local.region}:${local.account_id}:${var.apigateway.id}/*/${var.apigateway.routes[count.index].method}${var.apigateway.routes[count.index].path}"
}

####################### Lambda stuff  ###############################
//////////
module "terraform_lambda" {
  source = "github.com/JohnKoss/terraform_lambda"

  path       = var.lambda.path
  name       = var.lambda.name
  desc       = var.lambda.description
  timeout    = var.lambda.timeout
  other_args = var.lambda.other_args
  arch       = var.lambda.arch

  env_vars = var.lambda.env_vars

  managed_policies = var.lambda.managed_policies
  inline_policies  = var.lambda.inline_policies
}
#################################################




# # Equivalent of aws ecr get-login
# data "aws_ecr_authorization_token" "container_registry_token" {}

# // Be sure to start Docker Descktop.
# provider "docker" {
#   host = "tcp://127.0.0.1:2375" // The docker service running on this (local) computer
#   registry_auth {
#     address  = data.aws_ecr_authorization_token.container_registry_token.proxy_endpoint
#     username = data.aws_ecr_authorization_token.container_registry_token.user_name
#     password = data.aws_ecr_authorization_token.container_registry_token.password
#   }
# }

# #####
# resource "aws_ecr_repository" "ecr_repo" {
#   name = var.lambda.name
#   image_scanning_configuration {
#     scan_on_push = false
#   }
# }

# resource "aws_ecr_repository_policy" "ecr_repo_policy" {
#   repository = aws_ecr_repository.ecr_repo.name
#   policy = jsonencode({
#     Version = "2008-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "ecr:BatchGetImage",
#           "ecr:DeleteRepository",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:GetRepositoryPolicy",
#           "ecr:SetRepositoryPolicy"
#         ]
#       },
#     ]
#   })
# }

# #######
# locals {
#   context          = "${var.lambda.path}/context"
#   image_name       = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
#   sha1_dir         = sha1(join("", [for f in fileset(local.context, "**") : filesha1("${local.context}/${f}")]))
#   sha1_docker_file = md5(file("${var.lambda.path}/Dockerfile"))
# }

# #######
# resource "terraform_data" "docker_image" {

#   triggers_replace = {
#     sha1_dir         = local.sha1_dir
#     sha1_docker_file = local.sha1_docker_file
#   }

#   provisioner "local-exec" {
#     command = "docker build --ssh default -f ${var.lambda.path}/Dockerfile -t ${local.image_name} . && docker image prune --force"
#     environment = {
#       DOCKER_BUILDKIT = "1"
#     }
#   }
# }

# resource "docker_registry_image" "image_reg" {
#   name          = local.image_name
#   keep_remotely = false

#   triggers = {
#     sha1_dir         = local.sha1_dir
#     sha1_docker_file = local.sha1_docker_file
#   }

#   depends_on = [
#     terraform_data.docker_image
#   ]
# }

# ////////////////
# // https://github.com/hashicorp/terraform-provider-aws/issues/1110
# locals {
#   environment_map = var.lambda.env_vars[*]
# }

# resource "aws_lambda_function" "image" {
#   function_name = var.lambda.name
#   description   = var.lambda.description
#   timeout       = 5
#   image_uri     = local.image_name
#   package_type  = "Image"
#   architectures = ["arm64"]

#   role = aws_iam_role.iam_for_lambda.arn

#   dynamic "environment" {
#     for_each = local.environment_map
#     content {
#       variables = environment.value
#     }
#   }

#   // This also forces a dependency with ther ECR reopository
#   source_code_hash = trimprefix(docker_registry_image.image_reg.sha256_digest, "sha256:")

# }

# ####
# resource "aws_iam_role" "iam_for_lambda" {
#   name = var.lambda.name

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       },
#     ]
#   })
# }

# // Add the "AWSLambdaBasicExecutionRole" policy and any additional for the lambda.
# resource "aws_iam_role_policy_attachment" "lambda_policy" {
#   for_each = toset(concat(["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"], var.lambda.policies))

#   role       = aws_iam_role.iam_for_lambda.name
#   policy_arn = each.value
# }

# resource "aws_cloudwatch_log_group" "lambda_log" {
#   name = "/aws/lambda/${aws_lambda_function.image.function_name}"

#   retention_in_days = 1
# }






# # data "aws_caller_identity" "current" {}
# # data "aws_region" "current" {}

# # locals {
# #   account_id = data.aws_caller_identity.current.account_id
# #   region     = data.aws_region.current.id
# # }

# # ####################### APIGateway stuff  ###############################
# # resource "aws_apigatewayv2_integration" "lambda" {
# #   count                  = length(var.apigateway.routes)
# #   api_id                 = var.apigateway.id
# #   payload_format_version = "2.0"
# #   integration_uri        = aws_lambda_function.this.arn
# #   integration_type       = "AWS_PROXY"
# #   integration_method     = var.apigateway.routes[count.index].method
# # }


# # //// apigateway routes
# # resource "aws_apigatewayv2_route" "launch_path" {
# #   count              = length(var.apigateway.routes)
# #   api_id             = var.apigateway.id
# #   route_key          = "${var.apigateway.routes[count.index].method} ${var.apigateway.routes[count.index].path}"
# #   target             = "integrations/${aws_apigatewayv2_integration.lambda[count.index].id}"
# #   authorization_type = var.authorizer_type == null ? null : var.authorizer_type
# #   authorizer_id      = var.authorizer_id == null ? null : var.authorizer_id
# # }

# # // Permissions for apigateway to invoke the lambda functions
# # resource "aws_lambda_permission" "lambda" {
# #   count         = length(var.apigateway.routes)
# #   statement_id  = "AllowExecutionFromAPIGateway-${var.apigateway.routes[count.index].method}-${count.index}"
# #   action        = "lambda:InvokeFunction"
# #   principal     = "apigateway.amazonaws.com"
# #   function_name = var.lambda.name
# #   source_arn    = "arn:aws:execute-api:${local.region}:${local.account_id}:${var.apigateway.id}/*/${var.apigateway.routes[count.index].method}${var.apigateway.routes[count.index].path}"
# # }

# # ####################### Lambda stuff  ###############################

# # resource "null_resource" "lambda_build" {

# #   // Compile the Lambda function(s) when ever any of the *.go file changes
# #   triggers = {

# #     // For this trigger, terraform will set to false if not exists.
# #     archive_exists = fileexists("${var.lambda.path}/archive/${var.lambda.name}")

# #     // Check the hash of all file to see if there are any changes, which will cause an upload.
# #     dir_sha1 = sha1(join("", [for f in fileset("${var.lambda.path}", "*.*") : filesha1("${var.lambda.path}/${f}")]))
# #   }

# #   provisioner "local-exec" {
# #     command     = "go build -ldflags=-s -ldflags=-w -o archive/${var.lambda.name} ."
# #     working_dir = var.lambda.path
# #     environment = {
# #       GO111MODULE = "on"
# #       GOOS        = "linux"
# #     }
# #   }
# # }

# # // Zip and upload the complied lambda to AWS Lambda...
# # data "archive_file" "lambda_archive" {
# #   depends_on = [null_resource.lambda_build]

# #   type             = "zip"
# #   source_file      = "${var.lambda.path}/archive/${var.lambda.name}"
# #   output_path      = "${var.lambda.path}/archive/${var.lambda.name}.zip"
# #   output_file_mode = "0777"
# # }

# # ////////////////
# # // https://github.com/hashicorp/terraform-provider-aws/issues/1110
# # locals {
# #   environment_map = var.lambda.env_vars[*]
# # }

# # resource "aws_lambda_function" "this" {
# #   description   = var.lambda.description
# #   filename      = "${var.lambda.path}/archive/${var.lambda.name}.zip"
# #   function_name = var.lambda.name
# #   role          = aws_iam_role.iam_lambda_role.arn
# #   handler       = var.lambda.name

# #   // https://devcoops.com/terraform-aws-lambda-data-archive-file/
# #   source_code_hash = data.archive_file.lambda_archive.output_base64sha256

# #   runtime = "go1.x"

# #   dynamic "environment" {
# #     for_each = local.environment_map
# #     content {
# #       variables = environment.value
# #     }
# #   }
# # }

# # resource "aws_iam_role" "iam_lambda_role" {
# #   name = "_clearbyte_${var.lambda.name}"

# #   assume_role_policy = jsonencode({
# #     Version = "2012-10-17"
# #     Statement = [
# #       {
# #         Action = "sts:AssumeRole"
# #         Effect = "Allow"
# #         Principal = {
# #           Service = "lambda.amazonaws.com"
# #         }
# #       },
# #     ]
# #   })
# # }

# # // Add the "AWSLambdaBasicExecutionRole" policy and any additional for the lambda.
# # resource "aws_iam_role_policy_attachment" "lambda_policy" {
# #   for_each = toset(concat(["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"], var.lambda.policies))

# #   role       = aws_iam_role.iam_lambda_role.name
# #   policy_arn = each.value
# # }

# # resource "aws_cloudwatch_log_group" "lambda_log" {
# #   name = "/aws/lambda/${aws_lambda_function.this.function_name}"

# #   retention_in_days = 1
# # }
