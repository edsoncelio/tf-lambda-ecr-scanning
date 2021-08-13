locals {
  region = "us-east-1"
  default_tags = {
    CreatedBy = "Terraform"
    Project   = "tf_lambda_ecr_scanning"
  }

  #lambda variables
  lambda_role = {
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
  }

  lambda_inline_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
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
  }

  #eventbrigde variables
  event_pattern = {
    "detail-type" : [
      "ECR Image Scan"
    ],
    "detail" : {
      "scan-status" : [
        "COMPLETE"
      ],
    },
    "source" : [
      "aws.ecr"
    ],
  }



}