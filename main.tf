provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_policy" "lambda_permissions" {
  name        = "lambda-permissions-policy"
  description = "Politica cu permisiunile necesare pentru funcția Lambda"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:Publish"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_permissions_attachment" {
  name       = "lambda-permissions-attachment"
  policy_arn = aws_iam_policy.lambda_permissions.arn
  roles      = [aws_iam_role.lambda_exec.name]
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_sns_topic" "topic" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.email
}

output "sns_topic_arn" {
  value = aws_sns_topic.topic.arn
}

resource "aws_lambda_layer_version" "python_dep" {
  filename   = "python.zip"
  layer_name = "python_dep"
  compatible_runtimes = ["python3.8"]
}


resource "aws_lambda_function" "exchange_rate_function" {
  filename      = "lambda_function.zip"  
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  layers = [aws_lambda_layer_version.python_dep.arn]

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.topic.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "daily-lambda-trigger"
  schedule_expression = "cron(05 11 * * ? *)"  
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchange_rate_function.arn
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.daily_trigger.arn
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "target-lambda"

  arn = aws_lambda_function.exchange_rate_function.arn 
}