locals {
  root_config = read_terragrunt_config(find_in_parent_folders("root-config.hcl"))
  stage       = "dev"

  aws_credential_profile = "ML_SANDBOX_DEPLOY"

  tags = {
    environment = local.stage
  }
}

generate "provider_global" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
  required_version = "${local.root_config.locals.version_terraform}"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${local.root_config.locals.version_provider_aws}"
    }
  }
}

provider "aws" {
  region = "${local.root_config.locals.region}"
  profile = "${local.aws_credential_profile}"
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    profile        = local.aws_credential_profile
    bucket         = "${local.root_config.locals.project}-${local.stage}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
    region         = "${local.root_config.locals.region}"
    dynamodb_table = "${local.root_config.locals.project}-${local.stage}-terraform-state-locks"
  }
}