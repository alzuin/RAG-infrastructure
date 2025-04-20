# Optional: Private API Gateway only for internal use
resource "aws_api_gateway_rest_api" "internal_api" {
  name        = "${local.name_prefix}-internal_api"
  description = "Private API for internal calls"
  endpoint_configuration {
    types = ["PRIVATE"]
  }
}

# Lambda main embedding-api resource
resource "aws_api_gateway_resource" "embedding_api" {
  rest_api_id = aws_api_gateway_rest_api.internal_api.id
  parent_id   = aws_api_gateway_rest_api.internal_api.root_resource_id
  path_part   = "embedding-api"
}

# embedding-api resource for individual item operations (PUT/DELETE with ID)
resource "aws_api_gateway_resource" "embedding_api_item" {
  rest_api_id = aws_api_gateway_rest_api.internal_api.id
  parent_id   = aws_api_gateway_resource.embedding_api.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "message" {
  rest_api_id = aws_api_gateway_rest_api.internal_api.id
  parent_id   = aws_api_gateway_resource.chat_api.id
  path_part   = "message"
}

# POST method for creating new embeddings
resource "aws_api_gateway_method" "embedding_api_post" {
  rest_api_id   = aws_api_gateway_rest_api.internal_api.id
  resource_id   = aws_api_gateway_resource.embedding_api.id
  http_method   = "POST"
  authorization = "NONE"
}

# GET method for searching embeddings
resource "aws_api_gateway_method" "embedding_api_get" {
  rest_api_id   = aws_api_gateway_rest_api.internal_api.id
  resource_id   = aws_api_gateway_resource.embedding_api.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.query" = true
  }
}

# PUT method for updating specific embedding
resource "aws_api_gateway_method" "embedding_api_put" {
  rest_api_id   = aws_api_gateway_rest_api.internal_api.id
  resource_id   = aws_api_gateway_resource.embedding_api_item.id
  http_method   = "PUT"
  authorization = "NONE"
}

# DELETE method for removing specific embedding
resource "aws_api_gateway_method" "embedding_api_delete" {
  rest_api_id   = aws_api_gateway_rest_api.internal_api.id
  resource_id   = aws_api_gateway_resource.embedding_api_item.id
  http_method   = "DELETE"
  authorization = "NONE"
}


# Lambda integrations for each method
resource "aws_api_gateway_integration" "embedding_api_post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.internal_api.id
  resource_id             = aws_api_gateway_resource.embedding_api.id
  http_method             = aws_api_gateway_method.embedding_api_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.embedding_api.invoke_arn
}

resource "aws_api_gateway_integration" "embedding_api_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.internal_api.id
  resource_id             = aws_api_gateway_resource.embedding_api.id
  http_method             = aws_api_gateway_method.embedding_api_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.embedding_api.invoke_arn
}

resource "aws_api_gateway_integration" "embedding_api_put_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.internal_api.id
  resource_id             = aws_api_gateway_resource.embedding_api_item.id
  http_method             = aws_api_gateway_method.embedding_api_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.embedding_api.invoke_arn
}

resource "aws_api_gateway_integration" "embedding_api_delete_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.internal_api.id
  resource_id             = aws_api_gateway_resource.embedding_api_item.id
  http_method             = aws_api_gateway_method.embedding_api_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.embedding_api.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_post" {
  statement_id  = "AllowAPIGatewayInvokePost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.embedding_api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.internal_api.execution_arn}/*/POST/embedding-api"
}

resource "aws_lambda_permission" "allow_apigw_get" {
  statement_id  = "AllowAPIGatewayInvokeGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.embedding_api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.internal_api.execution_arn}/*/GET/embedding-api"
}

resource "aws_lambda_permission" "allow_apigw_put" {
  statement_id  = "AllowAPIGatewayInvokePut"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.embedding_api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.internal_api.execution_arn}/*/PUT/embedding-api/*"
}

resource "aws_lambda_permission" "allow_apigw_delete" {
  statement_id  = "AllowAPIGatewayInvokeDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.embedding_api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.internal_api.execution_arn}/*/DELETE/embedding-api/*"
}






resource "aws_api_gateway_resource" "chat_api" {
  rest_api_id = aws_api_gateway_rest_api.internal_api.id
  parent_id   = aws_api_gateway_rest_api.internal_api.root_resource_id
  path_part   = "chat-api"
}

resource "aws_api_gateway_method" "message_post" {
  rest_api_id   = aws_api_gateway_rest_api.internal_api.id
  resource_id   = aws_api_gateway_resource.message.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "message_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.internal_api.id
  resource_id             = aws_api_gateway_resource.message.id
  http_method             = aws_api_gateway_method.message_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.chat_api.invoke_arn
}



resource "aws_lambda_permission" "allow_apigw_chat" {
  statement_id  = "AllowAPIGatewayInvokeChat"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.internal_api.execution_arn}/*/POST/chat-api/message"
}

resource "aws_api_gateway_deployment" "internal_api" {
  depends_on = [
    aws_api_gateway_integration.embedding_api_post_lambda,
    aws_api_gateway_integration.embedding_api_get_lambda,
    aws_api_gateway_integration.embedding_api_put_lambda,
    aws_api_gateway_integration.embedding_api_delete_lambda,
    aws_api_gateway_integration.message_lambda
  ]
  rest_api_id = aws_api_gateway_rest_api.internal_api.id

  triggers = {
    redeployment = sha1(join(",", [
      aws_api_gateway_method.embedding_api_post.id,
      aws_api_gateway_method.embedding_api_get.id,
      aws_api_gateway_method.embedding_api_put.id,
      aws_api_gateway_method.embedding_api_delete.id,
      aws_api_gateway_integration.embedding_api_post_lambda.id,
      aws_api_gateway_integration.embedding_api_get_lambda.id,
      aws_api_gateway_integration.embedding_api_put_lambda.id,
      aws_api_gateway_integration.embedding_api_delete_lambda.id,
      aws_api_gateway_integration.message_lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.internal_api.id
  rest_api_id   = aws_api_gateway_rest_api.internal_api.id
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

resource "aws_api_gateway_rest_api_policy" "internal_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.internal_api.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "execute-api:Invoke",
        Resource  = "${aws_api_gateway_rest_api.internal_api.execution_arn}/*"
      }
    ]
  })
}


resource "aws_security_group" "api_gateway_endpoint_sg" {
  name        = "${local.name_prefix}-api-gateway-endpoint-sg"
  description = "Allow API Gateway interface endpoint access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "apigw" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id, aws_subnet.bastion_az2.id]
  security_group_ids  = [aws_security_group.api_gateway_endpoint_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "api-gateway-private-endpoint"
  }
}
