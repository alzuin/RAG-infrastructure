terraform {
  backend "s3" {
    bucket       = "terraform-state-poc-propmatch" # use the output value
    key          = "infra/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
