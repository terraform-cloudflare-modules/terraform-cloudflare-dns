output "clusters" {
  description = "Complete managed clusters keyed by input keys, including computed properties. Empty when disabled or unconfigured."
  value       = cloudflare_dns_firewall.this
}
