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
  input = "192.0.2.1"
}

resource "terraform_data" "flag" {
  input = false
}

module "subject" {
  source     = "../../.."
  account_id = terraform_data.account.output
  clusters = {
    shared = { name = "Shared DNS", upstream_ips = [terraform_data.value.output], ecs_fallback = terraform_data.flag.output }
  }
}

output "clusters" {
  description = "Known identities and properties while resource inputs are unknown."
  value       = module.subject.clusters
}
