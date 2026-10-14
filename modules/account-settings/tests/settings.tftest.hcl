mock_provider "cloudflare" {}

variables {
  account_id = "0123456789abcdef0123456789abcdef"
}

run "complete_settings_and_normalization" {
  command = apply
  variables {
    settings = {
      enforce_dns_only = false
      zone_defaults = {
        flatten_all_cnames  = false
        foundation_dns      = true
        multi_provider      = false
        ns_ttl              = 86400
        secondary_overrides = false
        zone_mode           = " DNS_ONLY "
        internal_dns        = { reference_zone_id = "reference-zone-id" }
        nameservers         = { type = " CLOUDFLARE.STANDARD.RANDOM " }
        soa = {
          expire  = 604800
          min_ttl = 60 # The provider requires 60–86400 seconds.
          mname   = "Primary.Example.NET."
          refresh = 10000
          retry   = 2400
          rname   = "Admin.Example.COM."
          ttl     = 3600
        }
      }
    }
  }
  assert {
    condition = (
      output.settings == cloudflare_account_dns_settings.this[0] && output.settings.account_id == var.account_id &&
      !output.settings.enforce_dns_only && !output.settings.zone_defaults.flatten_all_cnames &&
      output.settings.zone_defaults.foundation_dns && !output.settings.zone_defaults.multi_provider &&
      output.settings.zone_defaults.ns_ttl == 86400 && !output.settings.zone_defaults.secondary_overrides &&
      output.settings.zone_defaults.zone_mode == "dns_only" && output.settings.zone_defaults.internal_dns.reference_zone_id == "reference-zone-id" &&
      output.settings.zone_defaults.nameservers.type == "cloudflare.standard.random" &&
      output.settings.zone_defaults.soa.expire == 604800 && output.settings.zone_defaults.soa.min_ttl == 60 &&
      output.settings.zone_defaults.soa.mname == "Primary.Example.NET." && output.settings.zone_defaults.soa.refresh == 10000 &&
      output.settings.zone_defaults.soa.retry == 2400 && output.settings.zone_defaults.soa.rname == "Admin.Example.COM." &&
      output.settings.zone_defaults.soa.ttl == 3600
    )
    error_message = "All account settings must remain configurable, preserving false flags and SOA payloads while normalizing DNS enums."
  }
}

run "empty_configuration_defers_defaults" {
  command = plan
  assert {
    condition     = output.settings.account_id == var.account_id && output.settings.enforce_dns_only == null
    error_message = "An explicit module call manages one account while omitted properties defer to the provider."
  }
}

run "empty_nested_objects_and_optional_nameserver_type" {
  command = plan
  variables {
    settings = {
      enforce_dns_only = true
      zone_defaults    = { internal_dns = {}, nameservers = {}, soa = {} }
    }
  }
  assert {
    condition = (
      output.settings.enforce_dns_only && output.settings.zone_defaults.internal_dns != null &&
      output.settings.zone_defaults.nameservers != null && output.settings.zone_defaults.soa != null &&
      output.settings.zone_defaults.nameservers.type == null
    )
    error_message = "Account defaults must accept empty nested objects; their optional nameserver type differs from the zone settings schema."
  }
}

run "disabled" {
  command = plan
  variables {
    create     = false
    account_id = null
    settings   = { enforce_dns_only = true }
  }
  assert {
    condition     = output.settings == null && length(cloudflare_account_dns_settings.this) == 0
    error_message = "Disabling management must not require an account ID or create a resource."
  }
}

run "reject_missing_account" {
  command = plan
  variables {
    account_id = null
  }
  expect_failures = [cloudflare_account_dns_settings.this]
}

run "reject_invalid_zone_mode" {
  command = plan
  variables {
    settings = { zone_defaults = { zone_mode = "invalid" } }
  }
  expect_failures = [var.settings]
}
