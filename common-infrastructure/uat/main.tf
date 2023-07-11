module "generic" {
  source      = "../generic"
  environment = var.environment
  git_token   = var.git_token
}

terraform {
  backend "s3" {
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.54.0"
    }
  }
}
provider "aws" {
  region              = var.region
  profile             = "moar-${var.environment}"
  allowed_account_ids = [var.account_id]
}
