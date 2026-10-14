output "settings" {
  description = "Complete account-wide settings."
  value       = module.account_settings.settings
}

output "zone_id" {
  description = "New zone created after account defaults are applied."
  value       = module.dns.zone_id
}
