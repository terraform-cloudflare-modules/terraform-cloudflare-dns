mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = {
      id   = "023e105f4ecef8ad9ca31a8372d0c353"
      name = "example.com"
    }
  }
  mock_resource "cloudflare_zone" {
    defaults = {
      id = "023e105f4ecef8ad9ca31a8372d0c353"
    }
  }
}

variables {
  zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "unmanaged_by_default" {
  command = plan
  assert {
    condition     = length(cloudflare_zone_dns_settings.this) == 0 && output.dns_settings == null
    error_message = "Existing callers must not acquire ownership of zone-wide DNS settings."
  }
}

run "direct_id_settings_and_complete_output" {
  command = apply
  variables {
    create_dns_settings = true
    dns_settings = {
      flatten_all_cnames  = false
      foundation_dns      = false
      multi_provider      = false
      ns_ttl              = 86400
      secondary_overrides = false
      zone_mode           = " STANDARD "
      nameservers         = { type = " CLOUDFLARE.STANDARD ", ns_set = 2 }
      soa = {
        expire  = 604800
        min_ttl = 0
        mname   = "Primary.Example.NET."
        refresh = 10000
        retry   = 2400
        rname   = "Admin.Example.COM."
        ttl     = 3600
      }
    }
    records = {
      www = { name = "www", type = "A", content = "192.0.2.1" }
    }
  }
  assert {
    condition = (
      output.dns_settings == cloudflare_zone_dns_settings.this[0] &&
      output.dns_settings.zone_id == var.zone_id && output.dns_settings.zone_mode == "standard" &&
      !output.dns_settings.flatten_all_cnames && !output.dns_settings.foundation_dns &&
      !output.dns_settings.multi_provider && !output.dns_settings.secondary_overrides &&
      output.dns_settings.ns_ttl == 86400 && output.dns_settings.nameservers.type == "cloudflare.standard" &&
      output.dns_settings.nameservers.ns_set == 2
    )
    error_message = "Settings must preserve explicit false values, normalize enums, and expose the complete upstream resource."
  }
  assert {
    condition = (
      output.dns_settings.soa.expire == 604800 && output.dns_settings.soa.min_ttl == 0 &&
      output.dns_settings.soa.mname == "Primary.Example.NET." && output.dns_settings.soa.refresh == 10000 &&
      output.dns_settings.soa.retry == 2400 && output.dns_settings.soa.rname == "Admin.Example.COM." &&
      output.dns_settings.soa.ttl == 3600 && contains(keys(output.records), "www") &&
      length(cloudflare_zone.this) == 0 && length(data.cloudflare_zone.this) == 0 && output.dnssec == null
    )
    error_message = "All SOA fields, including zero and case-sensitive strings, must pass through without acquiring zone or DNSSEC ownership."
  }
}

run "lookup_and_custom_nameserver_set" {
  command = plan
  variables {
    zone_id             = null
    zone_filter         = { name = "example.com" }
    create_dns_settings = true
    dns_settings = {
      flatten_all_cnames = true
      multi_provider     = true
      zone_mode          = " DNS_ONLY "
      nameservers = {
        type              = " CUSTOM.ACCOUNT "
        nameserver_set_id = "0123456789abcdef0123456789abcdef"
      }
    }
  }
  assert {
    condition = (
      output.dns_settings.zone_id == output.zone_id && length(data.cloudflare_zone.this) == 1 &&
      output.dns_settings.flatten_all_cnames && output.dns_settings.multi_provider &&
      output.dns_settings.zone_mode == "dns_only" && output.dns_settings.nameservers.type == "custom.account" &&
      output.dns_settings.nameservers.nameserver_set_id == "0123456789abcdef0123456789abcdef"
    )
    error_message = "Zone filters must select the target while nameserver-set IDs and enabled flags pass through."
  }
}

run "managed_internal_zone" {
  command = apply
  variables {
    zone_id             = null
    create_zone         = true
    zone_name           = "example.internal"
    account_id          = "0123456789abcdef0123456789abcdef"
    zone                = { type = "internal" }
    create_dns_settings = true
    dns_settings = {
      internal_dns = { reference_zone_id = "0123456789abcdef0123456789abcdef" }
    }
  }
  assert {
    condition = (
      output.dns_settings.zone_id == cloudflare_zone.this[0].id && length(data.cloudflare_zone.this) == 0 &&
      output.dns_settings.internal_dns.reference_zone_id == "0123456789abcdef0123456789abcdef" && length(output.records) == 0
    )
    error_message = "Internal DNS reference zones must be configurable for newly managed zones without requiring records."
  }
}

run "secondary_zone_overrides" {
  command = plan
  variables {
    create_dns_settings = true
    dns_settings = {
      secondary_overrides = true
      zone_mode           = " CDN_ONLY "
    }
  }
  assert {
    condition     = output.dns_settings.secondary_overrides && output.dns_settings.zone_mode == "cdn_only"
    error_message = "Secondary overrides and the CDN-only mode must be configurable."
  }
}

run "empty_configuration_delegates_defaults" {
  command = plan
  variables {
    create_dns_settings = true
  }
  assert {
    condition     = length(cloudflare_zone_dns_settings.this) == 1 && output.dns_settings.zone_id == var.zone_id
    error_message = "An empty settings object must permit the provider to supply its defaults."
  }
}

run "empty_optional_nested_objects" {
  command = plan
  variables {
    create_dns_settings = true
    dns_settings = {
      internal_dns = {}
      soa          = {}
    }
  }
  assert {
    condition     = output.dns_settings.internal_dns != null && output.dns_settings.soa != null
    error_message = "Explicit empty optional objects must not be collapsed into omitted settings."
  }
}

run "global_disable_suppresses_settings" {
  command = plan
  variables {
    create              = false
    zone_id             = null
    create_zone         = true
    create_dns_settings = true
    dns_settings        = { multi_provider = true }
  }
  assert {
    condition     = length(cloudflare_zone_dns_settings.this) == 0 && output.dns_settings == null && length(cloudflare_zone.this) == 0
    error_message = "Global disable must suppress zone DNS settings without requiring selectors."
  }
}

run "reject_unmanaged_false_setting" {
  command = plan
  variables {
    dns_settings = { multi_provider = false }
  }
  expect_failures = [output.zone_id]
}

run "reject_unmanaged_empty_object" {
  command = plan
  variables {
    dns_settings = { soa = {} }
  }
  expect_failures = [output.zone_id]
}

run "reject_unknown_zone_mode" {
  command = plan
  variables {
    create_dns_settings = true
    dns_settings        = { zone_mode = "invalid" }
  }
  expect_failures = [var.dns_settings]
}

run "reject_fractional_nameserver_set" {
  command = plan
  variables {
    create_dns_settings = true
    dns_settings        = { nameservers = { type = "cloudflare.standard", ns_set = 1.5 } }
  }
  expect_failures = [var.dns_settings]
}

run "reject_null_nameserver_type" {
  command = plan
  variables {
    create_dns_settings = true
    dns_settings        = { nameservers = { type = null } }
  }
  expect_failures = [var.dns_settings]
}

run "reject_empty_nameserver_type" {
  command = plan
  variables {
    create_dns_settings = true
    dns_settings        = { nameservers = { type = " " } }
  }
  expect_failures = [var.dns_settings]
}
