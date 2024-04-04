locals {
  region = "us-east-1"

  version_terraform    = "=1.7.4"
  version_terragrunt   = "=0.55.11"
  version_provider_aws = "=4.57.0"

  project = "ml-sandbox"

  root_tags = {
    project = local.project
    developer = "JanSolo1"
  }
}