# S3 bucket to store Lambda deployment artifacts
resource "aws_s3_bucket" "lambda_code" {
  bucket        = "propmatch-lambda-code-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "propmatch-lambda-code"
  }
}

resource "aws_s3_bucket" "chatbot_prompts" {
  bucket        = "propmatch-chatbot-prompts-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "propmatch-chatbot-prompts"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}