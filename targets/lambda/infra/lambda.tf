resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "this" {
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda_execution.arn
  handler          = "com.shipstack.lambda.ReleaseHandler::handleRequest"
  runtime          = "java21"
  filename         = local.lambda_bootstrap_artifact
  source_code_hash = filebase64sha256(local.lambda_bootstrap_artifact)
  publish          = true
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      APP_VERSION = "terraform-bootstrap"
    }
  }

  depends_on = [aws_iam_role_policy.lambda_execution]

  lifecycle {
    # CodeBuild owns the active application package and release value.
    ignore_changes = [filename, source_code_hash, environment]
  }
}
