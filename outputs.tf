output "zone_id" {
  description = "Target zone ID, or null when disabled."
  value       = local.zone_id

  precondition {
    condition     = local.zone_selection_valid
    error_message = "Set exactly one of zone_id, zone_name, or zone_filter when create is true. Managed zones require zone_name and exclude zone_id and zone_filter."
  }
  precondition {
    condition     = local.account_selection_valid
    error_message = "Managed zones require account_id. Otherwise account_id is only supported with zone_name; use zone_filter.account for advanced lookups."
  }
  precondition {
    condition     = local.zone_options_valid
    error_message = "Zone properties require create_zone = true. Existing-zone lookups do not manage zone properties."
  }
}

output "zone_name" {
  description = "Normalized name of the managed or looked-up zone. Null in direct zone_id mode or when disabled."
  value       = local.zone_name
}

output "zone" {
  description = "Complete managed zone or zone lookup result, preserving its upstream schema and computed properties. Null in direct zone_id mode or when disabled."
  value       = local.zone
}

output "name_servers" {
  description = "Cloudflare-assigned nameservers for the managed or looked-up zone. Null in direct zone_id mode or when disabled. Registrar delegation is managed separately."
  value       = try(local.zone.name_servers, null)
}

output "records" {
  description = "Complete DNS resources keyed by the input record keys. Includes IDs, names, content, proxied (enabled), proxiable (capable), metadata, and timestamps. Empty when disabled."
  value       = cloudflare_dns_record.this
}
