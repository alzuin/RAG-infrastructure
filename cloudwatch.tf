resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/embedding-api"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "whatsapp_webhook_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.whatsapp_webhook.function_name}"
  retention_in_days = 7

  # Optional: make sure it's created before Lambda is invoked
  depends_on = [aws_lambda_function.whatsapp_webhook]
}

resource "aws_cloudwatch_log_group" "chat_api_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.chat_api.function_name}"
  retention_in_days = 7

  # Optional: make sure it's created before Lambda is invoked
  depends_on = [aws_lambda_function.chat_api]
}

resource "aws_cloudwatch_log_group" "embedding_api_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.embedding_api.function_name}"
  retention_in_days = 7

  # Optional: make sure it's created before Lambda is invoked
  depends_on = [aws_lambda_function.embedding_api]
}