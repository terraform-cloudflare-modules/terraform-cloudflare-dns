terraform {
  required_version = ">= 1.8"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.28.0, < 6.0.0"
    }
  }
}

variable "zone_id" {
  description = "Zone for the mocked records."
  type        = string
}

variable "records" {
  description = "Record configuration for each successive test apply."
  type        = any
}

variable "previous_records" {
  description = "Record outputs from the preceding apply, for identity comparisons."
  type        = any
  default     = null
}

module "dns" {
  source  = "../../.."
  zone_id = var.zone_id
  records = var.records
}

output "records" {
  description = "Managed records after this apply."
  value       = module.dns.records
}

output "previous_ids_preserved" {
  description = "Whether the previously managed records retain their IDs."
  value = var.previous_records == null ? true : alltrue([
    for key, record in var.previous_records : try(module.dns.records[key].id == record.id, false)
  ])
}
