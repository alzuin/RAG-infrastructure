variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

variable "efs_subnet_cidr" {
  type = string
}

variable "public_subnet_cidr_az2" {
  type = string
}

variable "qdrant_container_port" {
  type = string
}

variable "vpn_bastion_instance_type" {
  type = string
}

variable "my_home_ip_cidr" {
  type = string
}

variable "vpn_peer_cidr_block" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "ipsec_secrets" {
  type = string
}

variable "qdrant_internal_url" {
  type = string
}

variable "qdrant_collection" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "twilio_account_sid" {
  type = string
}

variable "twilio_auth_token" {
  type = string
}

variable "twilio_whatsapp_number" {
  type = string
}

variable "chat_api_url" {
  type = string
}

variable "llm_model_id" {
  type = string
}

variable "embed_model_id" {
  type = string
}

variable "account_email" {
  type = string
}

variable "OPENROUTER_API_KEY" {
  type = string
}

variable "prompt_domain" {
  type = string
}

variable "extraction_model" {
  type = string
}