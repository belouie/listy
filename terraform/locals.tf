data "aws_caller_identity" "current" {}

locals {
  account_id      = data.aws_caller_identity.current.account_id
  environment     = "dev"
  name            = "go-listy"
  region          = "us-east-1"
  tags = {
    Terraform   = "true"
    Environment = "listy-dev"
  }
}