data "aws_caller_identity" "current" {}

# IAM Policy for GitLab Terraform automation
resource "aws_iam_policy" "gitlab_terraform_policy" {
  name        = "${local.name_prefix}-GitLabTerraformPolicy"
  description = "Minimal Terraform permissions for GitLab CI"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowTerraformManageInfra"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "vpc:*",
          "iam:*",
          "efs:*",
          "elasticloadbalancing:*",
          "logs:*",
          "ecs:*",
          "ecr:*",
          "cloudwatch:*",
          "autoscaling:*",
          "s3:*",
          "dynamodb:*",
          "elasticfilesystem:*",
          "lambda:*",
          "apigateway:*",
          "servicediscovery:GetNamespace",
          "servicediscovery:GetService",
          "servicediscovery:ListNamespaces",
          "servicediscovery:ListServices",
          "servicediscovery:ListInstances",
          "servicediscovery:ListTagsForResource",
          "budgets:*"
        ]
        Resource = [
          "*",
          "arn:aws:servicediscovery:${var.region}:${data.aws_caller_identity.current.account_id}:namespace/*",
          "arn:aws:servicediscovery:${var.region}:${data.aws_caller_identity.current.account_id}:service/*"
        ]
      }
    ]
  })
}

# IAM user for GitLab CI
resource "aws_iam_user" "gitlab_ci_user" {
  name = "${local.name_prefix}-gitlab-terraform"
}

# Attach the policy to the GitLab user
resource "aws_iam_user_policy_attachment" "attach_gitlab_policy" {
  user       = aws_iam_user.gitlab_ci_user.name
  policy_arn = aws_iam_policy.gitlab_terraform_policy.arn
}

# Access key for GitLab CI (output it for manual copy)
resource "aws_iam_access_key" "gitlab_ci_access_key" {
  user = aws_iam_user.gitlab_ci_user.name
}

resource "null_resource" "create_ecs_service_linked_role" {
  triggers = {
    always_run = "once" # Change to force re-run if needed
  }

  provisioner "local-exec" {
    command = "aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com || echo 'Already exists'"
  }
}

# IAM role for Lambda with full permissions
resource "aws_iam_role" "lambda_exec_role" {
  name = "${local.name_prefix}-lambda-bedrock-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policies: CloudWatch Logs, Bedrock, and EC2 networking for VPC
resource "aws_iam_role_policy" "lambda_bedrock_policy" {
  name = "${local.name_prefix}-lambda-bedrock-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "api_gw_cloudwatch_role" {
  name = "${local.name_prefix}-api-gw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logs" {
  role       = aws_iam_role.api_gw_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "account" {
  depends_on = [aws_iam_role_policy_attachment.attach_cloudwatch_logs]

  cloudwatch_role_arn = aws_iam_role.api_gw_cloudwatch_role.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_chat_agent_dynamodb_policy" {
  name        = "${local.name_prefix}-lambda-chat-agent-dynamodb-policy"
  description = "Allow chat-agent Lambda to write and read from DynamoDB chat-history table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.name_prefix}-chat-history",
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.name_prefix}-chat-session-metadata"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chat_agent_dynamodb_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_chat_agent_dynamodb_policy.arn
}

resource "aws_iam_policy" "lambda_chat_agent_s3_prompt_policy" {
  name        = "${local.name_prefix}-lambda-chat-agent-s3-prompt-policy"
  description = "Allow chat-agent Lambda to read prompt templates from S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::propmatch-chatbot-prompts-ae08f857/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::propmatch-chatbot-prompts-ae08f857"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chat_agent_s3_prompt_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_chat_agent_s3_prompt_policy.arn
}