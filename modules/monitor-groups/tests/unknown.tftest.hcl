mock_provider "cloudflare" {}

run "unknown_values_preserve_identity" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  assert {
    condition     = length(output.groups) == 1 && output.groups.shared.description == "Shared checks"
    error_message = "Unknown account IDs, references, and settings must not determine resource counts or map keys."
  }
}
