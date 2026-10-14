terraform {
  required_version = ">= 1.8"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.28.0, < 6.0.0"
    }
  }
}

resource "terraform_data" "account" {
  input = "0123456789abcdef0123456789abcdef"
}

resource "terraform_data" "zone" {
  input = "023e105f4ecef8ad9ca31a8372d0c353"
}

resource "terraform_data" "secret" {
  input = base64encode("test-only-unknown-secret")
}

resource "terraform_data" "peer_ip" {
  input = "192.0.2.1"
}

module "transfers" {
  source = "../../.."

  account_id = terraform_data.account.output
  tsig_keys  = { signing = { algo = "hmac-sha256", secret = terraform_data.secret.output } }
  peers      = { primary = { ip = terraform_data.peer_ip.output, tsig_id = "signing" } }
  incoming   = { secondary = { zone_id = terraform_data.zone.output, name = "example.com", peers = ["primary"] } }
  outgoing   = { primary = { zone_id = terraform_data.zone.output, name = "example.com", peers = ["primary"] } }
}

output "tsig_key_ids" {
  description = "Non-secret TSIG IDs retain known keys while secrets and generated IDs are unknown."
  value       = module.transfers.tsig_key_ids
}

output "peers" {
  description = "Peers retain known identities while their account, IP, and signing ID are unknown."
  value       = module.transfers.peers
}

output "incoming" {
  description = "Incoming transfers retain known identities while zone and peer IDs are unknown."
  value       = module.transfers.incoming
}

output "outgoing" {
  description = "Outgoing transfers retain known identities while zone and peer IDs are unknown."
  value       = module.transfers.outgoing
}
