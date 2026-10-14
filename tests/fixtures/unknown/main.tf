terraform {
  required_version = ">= 1.8"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.28.0, < 6.0.0"
    }
  }
}

resource "terraform_data" "zone" {
  input = "023e105f4ecef8ad9ca31a8372d0c353"
}

resource "terraform_data" "content" {
  input = "192.0.2.1"
}

module "dns" {
  source  = "../../.."
  zone_id = terraform_data.zone.output

  records = {
    stable_key = {
      name    = "www"
      type    = "A"
      content = terraform_data.content.output
    }
  }
}

output "record_keys" {
  description = "Record identities while the zone ID and content are unknown."
  value       = keys(module.dns.records)
}

output "zone" {
  description = "Zone lookup result, absent in direct-ID mode."
  value       = module.dns.zone
}
