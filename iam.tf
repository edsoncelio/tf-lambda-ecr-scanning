
resource "aws_iam_role" "lambda_role" {
  name = "lambda_ecr_scanning_role"

  assume_role_policy = jsonencode(local.lambda_role)
  inline_policy {
    name = "lambda_ecr_policy"

    policy = jsonencode(local.lambda_inline_policy)
  }
} 