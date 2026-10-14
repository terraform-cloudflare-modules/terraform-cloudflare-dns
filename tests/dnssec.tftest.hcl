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
  mock_resource "cloudflare_zone_dnssec" {
    defaults = {
      id               = "023e105f4ecef8ad9ca31a8372d0c353"
      algorithm        = "13"
      digest           = "ABCDEF"
      digest_algorithm = "SHA256"
      digest_type      = "2"
      ds               = "example.com. 3600 IN DS 12345 13 2 ABCDEF"
      flags            = 257
      key_tag          = 12345
      key_type         = "ECDSAP256SHA256"
      modified_on      = "2026-01-01T00:00:00Z"
      public_key       = "test-public-key"
    }
  }
}

variables {
  zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "unmanaged_by_default" {
  command = plan
  assert {
    condition     = length(cloudflare_zone_dnssec.this) == 0 && output.dnssec == null && output.dnssec_ds == null
    error_message = "Existing callers must not acquire DNSSEC ownership or receive fabricated signing metadata."
  }
}

run "direct_id_signing_and_complete_outputs" {
  command = apply
  variables {
    create_dnssec = true
    dnssec = {
      status              = " ACTIVE "
      dnssec_multi_signer = false
      dnssec_presigned    = false
      dnssec_use_nsec3    = false
    }
    records = {
      www = { name = "www", type = "A", content = "192.0.2.1" }
    }
  }
  assert {
    condition = (
      length(cloudflare_zone.this) == 0 && length(data.cloudflare_zone.this) == 0 &&
      output.dnssec.zone_id == var.zone_id && output.dnssec.status == "active" &&
      !output.dnssec.dnssec_multi_signer && !output.dnssec.dnssec_presigned && !output.dnssec.dnssec_use_nsec3 &&
      contains(keys(output.records), "www") && output.records["www"].zone_id == output.dnssec.zone_id
    )
    error_message = "DNSSEC must work without zone ownership, normalize status, preserve false flags, and retain record keys."
  }
  assert {
    condition = (
      output.dnssec.id == var.zone_id && output.dnssec.algorithm == "13" &&
      output.dnssec.digest == "ABCDEF" && output.dnssec.digest_algorithm == "SHA256" &&
      output.dnssec.digest_type == "2" && output.dnssec.flags == 257 && output.dnssec.key_tag == 12345 &&
      output.dnssec.key_type == "ECDSAP256SHA256" && output.dnssec.modified_on == "2026-01-01T00:00:00Z" &&
      output.dnssec.public_key == "test-public-key" &&
      output.dnssec_ds == "example.com. 3600 IN DS 12345 13 2 ABCDEF" && output.dnssec_ds == output.dnssec.ds
    )
    error_message = "Complete DNSSEC outputs must retain all computed fields, including the full parent DS record."
  }
}

run "lookup_zone_and_multisigner" {
  command = plan
  variables {
    zone_id       = null
    zone_name     = "example.com"
    create_dnssec = true
    dnssec = {
      status              = "active"
      dnssec_multi_signer = true
      dnssec_presigned    = false
      dnssec_use_nsec3    = true
    }
    records = {
      external_key = { name = "@", type = "DNSKEY", data = { flags = 256, protocol = 3, algorithm = 13, public_key = "TestKey==" } }
    }
  }
  assert {
    condition = (
      output.dnssec.zone_id == output.zone_id && length(data.cloudflare_zone.this) == 1 &&
      output.dnssec.dnssec_multi_signer && output.dnssec.dnssec_use_nsec3 && !output.dnssec.dnssec_presigned &&
      output.records["external_key"].type == "DNSKEY"
    )
    error_message = "Looked-up zones must support multi-signer settings and externally supplied DNSKEY records."
  }
}

run "managed_zone_and_presigned_dnssec" {
  command = apply
  variables {
    zone_id       = null
    create_zone   = true
    zone_name     = "example.com"
    account_id    = "0123456789abcdef0123456789abcdef"
    zone          = { type = "secondary" }
    create_dnssec = true
    dnssec = {
      status              = "active"
      dnssec_multi_signer = false
      dnssec_presigned    = true
      dnssec_use_nsec3    = true
    }
  }
  assert {
    condition = (
      output.dnssec.zone_id == cloudflare_zone.this[0].id && length(data.cloudflare_zone.this) == 0 &&
      output.dnssec.dnssec_presigned && output.dnssec.dnssec_use_nsec3 && !output.dnssec.dnssec_multi_signer &&
      length(output.records) == 0
    )
    error_message = "DNSSEC must use the managed zone ID and support pre-signed mode without requiring module-managed records."
  }
}

run "unset_properties_defer_to_provider" {
  command = plan
  variables {
    create_dnssec = true
  }
  assert {
    condition = (
      length(cloudflare_zone_dnssec.this) == 1 && output.dnssec.status == null &&
      output.dnssec.dnssec_multi_signer == null && output.dnssec.dnssec_presigned == null && output.dnssec.dnssec_use_nsec3 == null
    )
    error_message = "Taking ownership must preserve omitted provider properties, including status."
  }
}

run "disabled_status_retains_ownership" {
  command = plan
  variables {
    create_dnssec = true
    dnssec        = { status = " DISABLED " }
  }
  assert {
    condition     = length(cloudflare_zone_dnssec.this) == 1 && output.dnssec.status == "disabled"
    error_message = "The disabled status must remain managed; it must not remove the DNSSEC resource."
  }
}

run "global_disable_suppresses_dnssec" {
  command = plan
  variables {
    create        = false
    zone_id       = null
    create_zone   = true
    create_dnssec = true
    dnssec        = { status = "active" }
  }
  assert {
    condition = (
      length(cloudflare_zone_dnssec.this) == 0 && output.dnssec == null && output.dnssec_ds == null &&
      length(cloudflare_zone.this) == 0 && length(data.cloudflare_zone.this) == 0
    )
    error_message = "Global disable must suppress DNSSEC even without valid zone selectors."
  }
}

run "reject_unmanaged_dnssec_properties" {
  command = plan
  variables {
    dnssec = { dnssec_multi_signer = false }
  }
  expect_failures = [output.zone_id]
}

run "reject_observed_status_as_configuration" {
  command = plan
  variables {
    create_dnssec = true
    dnssec        = { status = "pending" }
  }
  expect_failures = [var.dnssec]
}
