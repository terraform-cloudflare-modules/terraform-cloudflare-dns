mock_provider "cloudflare" {}

run "unknown_existing_zone_id_and_dns_settings" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  variables {
    create_dns_settings = true
  }
  assert {
    condition     = output.dns_settings != null && output.dns_settings.zone_mode == "standard" && contains(output.record_keys, "stable_key")
    error_message = "Unknown IDs and setting flags must not prevent planning DNS settings or stable record addresses."
  }
}

run "unknown_managed_zone_with_dns_settings_and_dnssec" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  variables {
    create_zone         = true
    create_dnssec       = true
    create_dns_settings = true
  }
  assert {
    condition = (
      output.dns_settings != null && output.dns_settings.zone_mode == "standard" &&
      output.dnssec != null && output.dnssec.status == "active" && output.record_name == "www.example.com"
    )
    error_message = "A new zone with an unknown account and ID must support DNS settings, DNSSEC, and records together."
  }
}

run "unknown_existing_zone_id_and_dnssec_setting" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  variables {
    create_dnssec = true
  }
  assert {
    condition     = output.dnssec != null && output.dnssec.status == "active" && contains(output.record_keys, "stable_key")
    error_message = "Unknown zone IDs and signing flags must not determine DNSSEC or record resource counts."
  }
}

run "unknown_managed_zone_id_and_dnssec_setting" {
  command = plan
  module {
    source = "./tests/fixtures/unknown"
  }
  variables {
    create_zone   = true
    create_dnssec = true
  }
  assert {
    condition     = output.dnssec != null && output.dnssec.status == "active" && output.record_name == "www.example.com"
    error_message = "DNSSEC must be plannable with a new zone whose account and ID are unknown."
  }
}

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
