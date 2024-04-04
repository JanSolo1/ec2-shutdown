include "root" {
  path   = find_in_parent_folders("root-config.hcl")
  expose = true
}

include "stage" {
  path   = find_in_parent_folders("stage.hcl")
  expose = true
}

locals {
  root_config  = read_terragrunt_config(find_in_parent_folders("root-config.hcl"))
  stage_config = read_terragrunt_config(find_in_parent_folders("stage.hcl"))
  inputs_from_tfvars = jsondecode(read_tfvars_file("ec2.tfvars"))

  # merge tags
  local_tags = {
    "Description" = "${local.root_config.locals.project}-ec2-shutdown-lambda-${local.stage_config.locals.stage}"
  }

  tags = merge(local.root_config.locals.root_tags, local.stage_config.locals.tags, local.local_tags )
}

inputs = {
    account = {
        region  = local.root_config.locals.region
        id      = get_aws_account_id()
    }

    tags    = local.tags
    stage   = local.stage_config.locals.stage
    ec2_id = local.inputs_from_tfvars.ec2_id
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/..//terraform/lambda/ec2_shutdown"
}