output "zone_id" {
  description = "Target zone ID, or null when disabled."
  value       = local.zone_id

  precondition {
    condition     = local.zone_selection_valid
    error_message = "Set exactly one of zone_id, zone_name, or zone_filter when create is true."
  }
  precondition {
    condition     = local.account_selection_valid
    error_message = "account_id is only supported with zone_name; use zone_filter.account for advanced lookups."
  }
}

output "zone_name" {
  description = "Canonical name of the looked-up zone. Null in direct zone_id mode or when disabled."
  value       = local.zone_name
}

output "zone" {
  description = "Complete zone lookup result, including computed properties. Null in direct zone_id mode or when disabled."
  value       = try(data.cloudflare_zone.this[0], null)
}

output "records" {
  description = "Complete DNS resources keyed by the input record keys. Includes IDs, names, content, proxied (enabled), proxiable (capable), metadata, and timestamps. Empty when disabled."
  value       = cloudflare_dns_record.this
}
