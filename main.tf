resource "aws_lambda_function" "lambda_ecr" {
    filename = "files/lambda_function_ecr.zip"
    function_name "ecr_lambda"
    role = aws_iam_role.lambda_role.arn
    handler = "index.lambda_handler"
    runtime = "python3.8"
    timeout = 900
    source_code_hash = filebase64sha256("files/lambda_function_ecr.zip")

}