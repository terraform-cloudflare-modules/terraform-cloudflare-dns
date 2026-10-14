output "views" {
  description = "Complete managed views keyed by input keys, including computed properties. Empty when disabled or unconfigured."
  value       = cloudflare_account_dns_settings_internal_view.this
}
