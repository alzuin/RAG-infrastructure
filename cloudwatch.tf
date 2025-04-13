resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/embedding-api"
  retention_in_days = 7
}
