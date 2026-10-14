terraform {
  required_version = ">= 1.8"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.28.0, < 6.0.0"
    }
  }
}

variable "create_zone" {
  description = "Exercise managed-zone creation with an unknown account ID."
  type        = bool
  default     = false
}

variable "multiple_values" {
  description = "Exercise list expansion with unknown content and MX priority values."
  type        = bool
  default     = false
}

resource "terraform_data" "zone" {
  input = "023e105f4ecef8ad9ca31a8372d0c353"
}

resource "terraform_data" "content" {
  input = "192.0.2.1"
}

module "dns" {
  source      = "../../.."
  create_zone = var.create_zone
  zone_id     = var.create_zone ? null : terraform_data.zone.output
  zone_name   = var.create_zone ? "example.com" : null
  account_id  = var.create_zone ? terraform_data.zone.output : null

  records = merge({
    stable_key = {
      name    = "www"
      type    = "A"
      content = terraform_data.content.output
    }
    }, var.multiple_values ? {
    addresses = {
      name    = "www"
      type    = "A"
      content = [terraform_data.content.output, "192.0.2.2"]
    }
    mail = {
      name    = "@"
      type    = "MX"
      content = ["${terraform_data.priority.output} mx.example.net", "20 mx2.example.net"]
    }
  } : {})
}

resource "terraform_data" "priority" {
  input = 10
}

output "record_name" {
  description = "Normalized record name even before a managed zone has an ID."
  value       = module.dns.records["stable_key"].name
}

output "record_keys" {
  description = "Record identities while the zone ID and content are unknown."
  value       = keys(module.dns.records)
}

output "zone" {
  description = "Zone lookup result, absent in direct-ID mode."
  value       = module.dns.zone
}
