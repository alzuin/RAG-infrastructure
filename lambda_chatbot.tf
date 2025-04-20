# Lambda and API Gateway for /chat-api/message

locals {
  chat_lambda_function_name = "${local.name_prefix}-chat-agent-lambda"
}

resource "aws_lambda_function" "chat_api" {
  function_name = local.chat_lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "main.handler"
  runtime       = "python3.11"
  timeout       = 30

  s3_bucket = aws_s3_bucket.lambda_code.bucket
  s3_key    = "lambda-code/chat-agent-lambda.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      QDRANT_URL         = var.qdrant_internal_url
      QDRANT_COLLECTION  = var.qdrant_collection
      DDB_TABLE          = aws_dynamodb_table.chat_history.name
      MODEL_ID           = var.llm_model_id
      EMBED_MODEL_ID     = var.embed_model_id
      OPENROUTER_API_KEY = var.OPENROUTER_API_KEY
      DDB_METADATA_TABLE = aws_dynamodb_table.chat_session_metadata.name
      PROMPT_S3_BUCKET   = aws_s3_bucket.chatbot_prompts.bucket
      PROMPT_DOMAIN      = var.prompt_domain
      EXTRACTION_MODEL   = var.extraction_model
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

resource "aws_dynamodb_table" "chat_history" {
  name         = "${local.name_prefix}-chat-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Name = "chat-history"
  }
}

resource "aws_dynamodb_table" "chat_session_metadata" {
  name         = "${local.name_prefix}-chat-session-metadata"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "user_id"
  range_key = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Name = "chat-session-metadata"
  }
}
