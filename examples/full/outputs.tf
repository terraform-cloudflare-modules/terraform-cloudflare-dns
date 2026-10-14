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

output "dnssec" {
  description = "Complete DNSSEC configuration and signing metadata."
  value       = module.dns.dnssec
}

output "dnssec_ds" {
  description = "DS record to publish through the registrar or parent zone after enabling DNSSEC."
  value       = module.dns.dnssec_ds
}

output "dns_settings" {
  description = "Complete zone-wide DNS settings."
  value       = module.dns.dns_settings
}

output "load_balancers" {
  description = "Complete load balancer resources, including resolved geographic pool references."
  value       = module.dns.load_balancers
}

output "load_balancer_pools" {
  description = "Account-level pools and their Cloudflare IDs."
  value       = module.dns.load_balancer_pools
}

output "load_balancer_monitors" {
  description = "Account-level health monitors and their Cloudflare IDs."
  value       = module.dns.load_balancer_monitors
}
