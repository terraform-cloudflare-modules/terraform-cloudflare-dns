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

run "unknown_account_and_zone_id_keep_stable_addresses" {
  command = plan

  module {
    source = "./tests/fixtures/unknown"
  }

  variables {
    create_zone = true
  }

  assert {
    condition     = length(output.record_keys) == 1 && contains(output.record_keys, "stable_key") && output.record_name == "www.example.com"
    error_message = "Unknown account and generated zone IDs must not prevent planning record identities or fully qualified names."
  }
}

run "unknown_list_values_keep_stable_addresses" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  variables {
    multiple_values = true
  }
  assert {
    condition = (
      length(output.record_keys) == 5 && contains(output.record_keys, "stable_key") &&
      contains(output.record_keys, "addresses[0]") && contains(output.record_keys, "addresses[1]") &&
      contains(output.record_keys, "mail[0]") && contains(output.record_keys, "mail[1]")
    )
    error_message = "Known list lengths must allow planning even when record content and priorities are unknown."
  }
}
