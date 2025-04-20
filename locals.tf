locals {
  env         = var.stage_name
  name_prefix = "pm-${local.env}" # For full names like pm-staging-xyz
  name_suffix = local.env         # For short tags
  tags = {
    Environment = local.env
    Project     = "propmatch"
    ManagedBy   = "Terraform"
  }
}