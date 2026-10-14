mock_provider "cloudflare" {}

run "unknown_values_preserve_identity" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  assert {
    condition     = output.settings != null && output.settings.zone_defaults.zone_mode == "standard"
    error_message = "Unknown account IDs, references, and settings must not determine resource counts or map keys."
  }
}
