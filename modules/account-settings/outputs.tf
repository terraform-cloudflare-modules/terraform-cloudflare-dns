output "settings" {
  description = "Complete account DNS settings, or null when disabled."
  value       = one(cloudflare_account_dns_settings.this)
}
