output "acls" {
  description = "Complete managed transfer ACLs keyed by input keys. Empty when disabled."
  value       = cloudflare_dns_zone_transfers_acl.this
}

output "tsig_keys" {
  description = "Complete managed TSIG resources, including secrets, keyed by input keys. Sensitive; empty when disabled."
  value       = cloudflare_dns_zone_transfers_tsig.this
  sensitive   = true
}

output "tsig_key_ids" {
  description = "Managed TSIG IDs keyed by input keys, without secret material."
  value       = local.tsig_key_ids
}

output "peers" {
  description = "Complete managed peers keyed by input keys, including resolved TSIG IDs. Empty when disabled."
  value       = cloudflare_dns_zone_transfers_peer.this
}

output "incoming" {
  description = "Complete incoming transfers keyed by input keys, including resolved peer IDs, SOA serials, and timestamps. Empty when disabled."
  value       = cloudflare_dns_zone_transfers_incoming.this
}

output "outgoing" {
  description = "Complete outgoing transfers keyed by input keys, including resolved peer IDs, SOA serials, and timestamps. Empty when disabled."
  value       = cloudflare_dns_zone_transfers_outgoing.this
}
