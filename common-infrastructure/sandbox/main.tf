module "generic" {
  source      = "../generic"
  environment = var.environment
}

terraform {
  backend "s3" {
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.13.0"
    }
  }
}
provider "aws" {
  region              = var.region
  profile             = "moar-${var.environment}"
  allowed_account_ids = [var.account_id]
}
