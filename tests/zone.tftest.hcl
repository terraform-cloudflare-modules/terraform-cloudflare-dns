mock_provider "cloudflare" {
  mock_resource "cloudflare_zone" {
    defaults = {
      id                    = "023e105f4ecef8ad9ca31a8372d0c353"
      name_servers          = ["alice.ns.cloudflare.com", "bob.ns.cloudflare.com"]
      original_name_servers = ["ns.example.net"]
      status                = "pending"
      verification_key      = "zone-verification"
    }
  }
  mock_data "cloudflare_zone" {
    defaults = {
      id           = "023e105f4ecef8ad9ca31a8372d0c353"
      name         = "example.com"
      name_servers = ["alice.ns.cloudflare.com", "bob.ns.cloudflare.com"]
    }
  }
}

run "manage_zone_and_records" {
  command = apply

  variables {
    create_zone = true
    zone_name   = " EXAMPLE.COM. "
    account_id  = "0123456789abcdef0123456789abcdef"
    zone = {
      type                = "full"
      paused              = false
      vanity_name_servers = ["ns1.example.com", "ns2.example.com"]
    }
    records = {
      www  = { type = "A", content = "192.0.2.10" }
      apex = { name = "@", type = "TXT", content = "verification" }
    }
  }

  assert {
    condition = (
      length(data.cloudflare_zone.this) == 0 &&
      output.zone.name == "example.com" &&
      output.zone.account.id == var.account_id &&
      output.zone.type == "full" && !output.zone.paused &&
      output.zone.vanity_name_servers == tolist(var.zone.vanity_name_servers)
    )
    error_message = "Managed zones must normalize the domain, honor configuration and bypass lookup."
  }
  assert {
    condition = (
      output.records["www"].zone_id == output.zone_id &&
      output.records["www"].name == "www.example.com" &&
      output.records["apex"].name == "example.com" &&
      output.zone_id == output.zone.id && output.zone_name == output.zone.name
    )
    error_message = "Records must depend on the managed zone ID while retaining key and name semantics."
  }
  assert {
    condition = (
      output.name_servers == output.zone.name_servers &&
      contains(output.name_servers, "alice.ns.cloudflare.com") &&
      output.zone.verification_key == "zone-verification" &&
      output.zone.status == "pending" &&
      contains(output.zone.original_name_servers, "ns.example.net")
    )
    error_message = "Whole-zone outputs must retain delegation and ownership-verification information."
  }
}

run "zone_without_records_and_empty_nameserver_override" {
  command = plan
  variables {
    create_zone = true
    zone_name   = "example.com"
    account_id  = "0123456789abcdef0123456789abcdef"
    zone = {
      paused              = true
      vanity_name_servers = []
    }
  }
  assert {
    condition = (
      length(cloudflare_zone.this) == 1 && length(output.records) == 0 &&
      cloudflare_zone.this[0].paused && length(cloudflare_zone.this[0].vanity_name_servers) == 0
    )
    error_message = "Zone-only management must support pausing and explicitly clearing custom nameservers."
  }
}

run "existing_zone_remains_lookup_only" {
  command = plan
  variables {
    zone_name = "example.com"
  }
  assert {
    condition = (
      length(cloudflare_zone.this) == 0 && length(data.cloudflare_zone.this) == 1 &&
      output.zone.id == output.zone_id && contains(output.name_servers, "alice.ns.cloudflare.com")
    )
    error_message = "Existing callers must keep lookup-only behavior and receive nameserver outputs."
  }
}

run "direct_id_remains_unmanaged" {
  command = plan
  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
  }
  assert {
    condition     = length(cloudflare_zone.this) == 0 && length(data.cloudflare_zone.this) == 0 && output.zone == null && output.name_servers == null
    error_message = "Direct-ID consumers must not acquire zone ownership or trigger lookup."
  }
}

run "disabled_managed_zone" {
  command = plan
  variables {
    create      = false
    create_zone = true
    records     = { www = { type = "A", content = "192.0.2.10" } }
  }
  assert {
    condition = (
      length(cloudflare_zone.this) == 0 && length(data.cloudflare_zone.this) == 0 &&
      length(output.records) == 0 && output.zone == null && output.zone_id == null &&
      output.zone_name == null && output.name_servers == null
    )
    error_message = "Disabled modules must suppress zone creation, lookup and records without requiring selectors."
  }
}

run "reject_managed_zone_without_account" {
  command = plan
  variables {
    create_zone = true
    zone_name   = "example.com"
  }
  expect_failures = [cloudflare_zone.this]
}

run "reject_managed_zone_without_name" {
  command = plan
  variables {
    create_zone = true
    account_id  = "0123456789abcdef0123456789abcdef"
  }
  expect_failures = [cloudflare_zone.this]
}

run "reject_managed_zone_with_id" {
  command = plan
  variables {
    create_zone = true
    zone_name   = "example.com"
    account_id  = "0123456789abcdef0123456789abcdef"
    zone_id     = "023e105f4ecef8ad9ca31a8372d0c353"
  }
  expect_failures = [cloudflare_zone.this]
}

run "reject_managed_zone_with_filter" {
  command = plan
  variables {
    create_zone = true
    zone_name   = "example.com"
    account_id  = "0123456789abcdef0123456789abcdef"
    zone_filter = { name = "example.com" }
  }
  expect_failures = [cloudflare_zone.this]
}

run "reject_unmanaged_zone_properties" {
  command = plan
  variables {
    zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
    zone    = { paused = false }
  }
  expect_failures = [output.zone_id]
}
