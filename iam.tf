
resource "aws_iam_role" "lambda_role" {
  name = "lambda_ecr_scanning_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = "lambda_ecr_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
              "ecr:DescribeImageScanFindings",
              "logs:CreateLogStream",
              "logs:GetLogEvents",
              "logs:PutLogEvents",
              "logs:CreateLogGroup"
              ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
}