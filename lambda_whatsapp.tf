locals {
  whatsapp_lambda_function_name = "${local.name_prefix}-whatsapp-webhook"
}

resource "aws_lambda_function" "whatsapp_webhook" {
  function_name = local.whatsapp_lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "main.handler"
  runtime       = "python3.11"
  timeout       = 30

  s3_bucket = aws_s3_bucket.lambda_code.bucket
  s3_key    = "lambda-code/whatsapp_webhook.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      TWILIO_ACCOUNT_SID     = var.twilio_account_sid
      TWILIO_AUTH_TOKEN      = var.twilio_auth_token
      TWILIO_WHATSAPP_NUMBER = var.twilio_whatsapp_number
      CHAT_API_URL           = var.chat_api_url
    }
  }

  lifecycle {
    ignore_changes = [
      s3_bucket,
      s3_key
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_exec]
}