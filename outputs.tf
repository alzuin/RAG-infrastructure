output "gitlab_ci_access_key_id" {
  value     = aws_iam_access_key.gitlab_ci_access_key.id
  sensitive = false
}

output "gitlab_ci_secret_access_key" {
  value     = aws_iam_access_key.gitlab_ci_access_key.secret
  sensitive = true
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "efs_id" {
  value = aws_efs_file_system.qdrant_data.id
}

output "vpn_bastion_public_ip" {
  value       = aws_eip.vpn_bastion.public_ip
  description = "Use this IP to configure the VPN on Unifi"
}

output "lambda_code_bucket" {
  value = aws_s3_bucket.lambda_code.bucket
}

output "internal_api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.internal_api.id}.execute-api.${var.region}.amazonaws.com/"
}

output "external_api_gateway_invoke_url" {
  value       = "https://${aws_api_gateway_rest_api.external_api.id}.execute-api.${var.region}.amazonaws.com/"
  description = "Public REST API URL for Twilio to call the WhatsApp webhook"
}