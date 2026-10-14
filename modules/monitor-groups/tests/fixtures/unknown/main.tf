terraform {
  required_version = ">= 1.8"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.28.0, < 6.0.0"
    }
  }
}

resource "terraform_data" "account" {
  input = "0123456789abcdef0123456789abcdef"
}

resource "terraform_data" "value" {
  input = "023e105f4ecef8ad9ca31a8372d0c353"
}

resource "terraform_data" "flag" {
  input = false
}

module "subject" {
  source     = "../../.."
  account_id = terraform_data.account.output
  groups = {
    shared = { description = "Shared checks", members = [{
      monitor_id      = terraform_data.value.output
      enabled         = terraform_data.flag.output
      monitoring_only = false
      must_be_healthy = true
    }] }
  }
}

output "groups" {
  description = "Known identities and properties while resource inputs are unknown."
  value       = module.subject.groups
}
