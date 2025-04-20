resource "aws_api_gateway_rest_api" "external_api" {
  name        = "${local.name_prefix}-external_api"
  description = "Public API for external calls"
}

resource "aws_api_gateway_resource" "whatsapp_api" {
  rest_api_id = aws_api_gateway_rest_api.external_api.id
  parent_id   = aws_api_gateway_rest_api.external_api.root_resource_id
  path_part   = "whatsapp"
}

resource "aws_api_gateway_resource" "whatsapp_webhook" {
  rest_api_id = aws_api_gateway_rest_api.external_api.id
  parent_id   = aws_api_gateway_resource.whatsapp_api.id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "whatsapp_webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.external_api.id
  resource_id   = aws_api_gateway_resource.whatsapp_webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "whatsapp_webhook_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.external_api.id
  resource_id             = aws_api_gateway_resource.whatsapp_webhook.id
  http_method             = aws_api_gateway_method.whatsapp_webhook_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.whatsapp_webhook.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.whatsapp_webhook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.external_api.id}/${aws_api_gateway_stage.prod.stage_name}/POST/whatsapp/webhook"
}

resource "aws_api_gateway_deployment" "external_api" {
  depends_on = [
    aws_api_gateway_integration.whatsapp_webhook_lambda
  ]
  rest_api_id = aws_api_gateway_rest_api.external_api.id

  triggers = {
    redeployment = sha1(join(",", [
      aws_api_gateway_method.whatsapp_webhook_post.id,
      aws_api_gateway_integration.whatsapp_webhook_lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod_ext" {
  deployment_id = aws_api_gateway_deployment.external_api.id
  rest_api_id   = aws_api_gateway_rest_api.external_api.id
  stage_name    = var.stage_name
  depends_on    = [aws_api_gateway_account.account]
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_api_gateway_rest_api_policy" "external_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.external_api.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "execute-api:Invoke",
        Resource  = "${aws_api_gateway_rest_api.external_api.execution_arn}/*"
      }
    ]
  })
}

