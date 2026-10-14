output "records" {
  description = "Managed records with their Cloudflare IDs and computed properties."
  value       = module.dns.records
}
