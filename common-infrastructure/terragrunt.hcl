
locals {
  environment = basename(path_relative_to_include())
  accounts = {
    sandbox = "846417192786"
    dev     = "758924794885"
    uat     = "699573796741"
    prod    = "755229875957"
  }
}

remote_state {
  backend = "s3"
  config = {
    encrypt = true
    bucket  = "${local.environment}-codebuild-ecr-repo-tfstate"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    profile = get_env("TERRAGRUNT_DISABLE_PROFILE", "false") == "true" ? null : "moar-${local.environment}"
    dynamodb_table = "${local.environment}-codebuild-ecr-repo-tfstate"
  }
}

terraform {
  /* plan args */
  extra_arguments "plan_args" {
    commands = [
      "plan"
    ]

    arguments = [
      "-out=${get_terragrunt_dir()}/terraform_${local.environment}.tfplan",
      "-lock=true",
      "-lock-timeout=60s"
    ]
  }

  # apply args
  extra_arguments "apply_args" {
    commands = [
      "apply"
    ]

    arguments = [
      "-lock=true",
      "-lock-timeout=60s"
    ]
  }

  extra_arguments "vars" {
    commands = [
      "apply",
      "plan",
      "import",
      "push",
      "refresh",
      "destroy"
    ]

    # .tfvars for set variables
    # .vars for declared variables
    #required_var_files = [
    #  "${get_terragrunt_dir()}/../../${basename(path_relative_to_include())}.tfvars"
    #]

    # optional_var_files = [
    # ]

  }
}


inputs = {
  environment = "${local.environment}"
  region      = "eu-west-1"
  account_id  = local.accounts["${local.environment}"]
  git_token = "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"
}
