locals {
  # Only the identifiers used for resource addresses are declassified.
  # Credentials and all TSIG resource arguments retain their sensitivity.
  tsig_keys    = var.create ? nonsensitive(toset(keys(var.tsig_keys))) : toset([])
  tsig_key_ids = { for key, tsig in cloudflare_dns_zone_transfers_tsig.this : key => tsig.id }
  peer_ids     = { for key, peer in cloudflare_dns_zone_transfers_peer.this : key => peer.id }
}
