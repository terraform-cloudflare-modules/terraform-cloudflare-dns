output "records" {
  description = "Managed records with their Cloudflare IDs and computed properties."
  value       = module.dns.records
}

output "zone" {
  description = "Complete managed zone, including delegation and verification information."
  value       = module.dns.zone
}

output "name_servers" {
  description = "Cloudflare-assigned nameservers to configure at the registrar or parent zone."
  value       = module.dns.name_servers
}
