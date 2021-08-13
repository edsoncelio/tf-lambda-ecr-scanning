resource "aws_lambda_function" "lambda_ecr" {
  filename         = "files/index.zip"
  function_name    = "ecr_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.8"
  timeout          = 900
  source_code_hash = filebase64sha256("files/index.zip")

}

resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  name          = "CloudWatch_Event_Rule_To_Lambda"
  description   = "cloudwatch event rule to be used with lambda ecr"
  event_pattern = jsonencode(local.event_pattern)
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ecr.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule.arn

  depends_on = [
    aws_cloudwatch_event_rule.cloudwatch_event_rule,
  ]
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  rule = aws_cloudwatch_event_rule.cloudwatch_event_rule.name
  arn  = aws_lambda_function.lambda_ecr.arn
}

