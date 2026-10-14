mock_provider "cloudflare" {}

run "unknown_accounts_zones_ids_and_secrets" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  assert {
    condition = (
      length(output.tsig_key_ids) == 1 && contains(keys(output.tsig_key_ids), "signing") &&
      length(output.peers) == 1 && output.peers.primary.name == "primary" &&
      length(output.incoming) == 1 && output.incoming.secondary.name == "example.com" &&
      length(output.outgoing) == 1 && output.outgoing.primary.name == "example.com"
    )
    error_message = "Unknown resource IDs and sensitive secrets must not affect for_each addresses or unrelated known properties."
  }
}
