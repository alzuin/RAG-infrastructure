# Lambda + Bedrock setup with internal-only access and future messaging readiness

locals {
  embedding_lambda_function_name = "${local.name_prefix}-embedding-api-lambda"
  vpc_name                       = "main"
}

resource "aws_lambda_function" "embedding_api" {
  function_name = local.embedding_lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.11"
  handler       = "main.handler"
  timeout       = 30

  s3_bucket = aws_s3_bucket.lambda_code.bucket
  s3_key    = "lambda-code/embedding-api.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      QDRANT_URL     = var.qdrant_internal_url
      EMBED_MODEL_ID = var.embed_model_id
    }
  }

  lifecycle {
    ignore_changes = [
      s3_bucket,
      s3_key
    ]
  }
}

resource "aws_security_group" "lambda_sg" {
  name   = "${local.name_prefix}-lambda-embedding-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
