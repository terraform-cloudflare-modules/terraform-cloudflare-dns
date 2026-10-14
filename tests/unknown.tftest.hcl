mock_provider "cloudflare" {}

run "unknown_id_and_content_keep_stable_addresses" {
  command = plan

  module {
    source = "./tests/fixtures/unknown"
  }

  assert {
    condition     = length(output.record_keys) == 1 && contains(output.record_keys, "stable_key") && output.zone == null
    error_message = "Unknown zone IDs and content must not determine lookup count or record keys."
  }
}
