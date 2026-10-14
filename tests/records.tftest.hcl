mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = {
      id   = "023e105f4ecef8ad9ca31a8372d0c353"
      name = "example.com"
    }
  }
}


variables {
  zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "names_defaults_and_payloads" {
  command = plan

  variables {
    zone_id    = null
    zone_name  = " EXAMPLE.COM. "
    account_id = "0123456789abcdef0123456789abcdef"
    records = {
      WWW        = { type = " a ", content = "192.0.2.10" }
      apex       = { name = "@", type = "MX", content = "Mail.EXAMPLE.com.", priority = 10 }
      empty_apex = { name = "", type = "TXT", content = "  Mixed Case TXT  " }
      wildcard   = { name = "*.", type = "CNAME", content = "Target.Example.NET." }
      explicit   = { full_name = "_Acme-Challenge.Example.COM.", type = "TXT", content = "DoNotChangeMe" }
    }
  }

  assert {
    condition = (
      cloudflare_dns_record.this["WWW"].name == "www.example.com" &&
      cloudflare_dns_record.this["WWW"].type == "A" &&
      cloudflare_dns_record.this["WWW"].ttl == 1 &&
      cloudflare_dns_record.this["WWW"].proxied == false &&
      cloudflare_dns_record.this["apex"].name == "example.com" &&
      cloudflare_dns_record.this["empty_apex"].name == "example.com" &&
      cloudflare_dns_record.this["wildcard"].name == "*.example.com" &&
      cloudflare_dns_record.this["explicit"].name == "_acme-challenge.example.com"
    )
    error_message = "DNS names, types, or defaults were not normalized correctly."
  }
  assert {
    condition = (
      cloudflare_dns_record.this["apex"].content == "Mail.EXAMPLE.com." &&
      cloudflare_dns_record.this["empty_apex"].content == "  Mixed Case TXT  " &&
      cloudflare_dns_record.this["wildcard"].content == "Target.Example.NET." &&
      cloudflare_dns_record.this["explicit"].content == "DoNotChangeMe"
    )
    error_message = "Record content must be preserved byte-for-byte."
  }
  assert {
    condition = (
      data.cloudflare_zone.this[0].filter.name == "example.com" &&
      data.cloudflare_zone.this[0].filter.account.id == "0123456789abcdef0123456789abcdef" &&
      output.zone_name == "example.com"
    )
    error_message = "The normalized zone lookup must include its account."
  }
}

run "explicit_empty_values_override_defaults" {
  command = plan
  variables {
    defaults = {
      comment                 = "inherited"
      tags                    = ["owner:dns"]
      ttl                     = 3600
      proxied                 = true
      private_routing         = true
      include_shadow_metadata = true
      settings                = { ipv4_only = true }
    }
    records = {
      clear = {
        type                    = "TXT"
        content                 = ""
        comment                 = ""
        tags                    = []
        settings                = {}
        proxied                 = false
        private_routing         = false
        include_shadow_metadata = false
      }
      inherit = {
        type    = "A"
        content = "192.0.2.11"
        ttl     = 1
      }
    }
  }
  assert {
    condition = (
      cloudflare_dns_record.this["clear"].comment == "" &&
      length(cloudflare_dns_record.this["clear"].tags) == 0 &&
      cloudflare_dns_record.this["clear"].content == "" &&
      cloudflare_dns_record.this["clear"].ttl == 3600 &&
      cloudflare_dns_record.this["clear"].proxied == false &&
      cloudflare_dns_record.this["clear"].private_routing == false &&
      cloudflare_dns_record.this["clear"].include_shadow_metadata == false &&
      local.records["clear"].settings.ipv4_only == null
    )
    error_message = "Empty values and false must override inherited defaults."
  }
  assert {
    condition = (
      cloudflare_dns_record.this["inherit"].comment == "inherited" &&
      contains(cloudflare_dns_record.this["inherit"].tags, "owner:dns") &&
      cloudflare_dns_record.this["inherit"].settings.ipv4_only == true &&
      cloudflare_dns_record.this["inherit"].private_routing == true &&
      cloudflare_dns_record.this["inherit"].include_shadow_metadata == true
    )
    error_message = "Unset fields must inherit defaults."
  }
}

run "mixed_structured_record_types" {
  command = plan
  variables {
    records = {
      caa = {
        name = "@"
        type = "CAA"
        data = { flags = 0, tag = "issue", value = "letsencrypt.org" }
      }
      dnskey = {
        type = "DNSKEY"
        data = { flags = 257, protocol = 3, algorithm = 13, public_key = "TestKey==" }
      }
      naptr = {
        type = "NAPTR"
        data = { flags = "S", order = 10, preference = 20, service = "SIP+D2U", regex = "", replacement = "_sip._udp.example.com." }
      }
      srv = {
        name = "_sip._tcp"
        type = "SRV"
        data = { priority = 10, weight = 20, port = 5060, target = "Sip.EXAMPLE.com." }
      }
      loc = {
        type = "LOC"
        data = {
          altitude       = 12.5, lat_degrees = 52, lat_direction = "N", lat_minutes = 31, lat_seconds = 12.5
          long_degrees   = 13, long_direction = "E", long_minutes = 24, long_seconds = 10.5
          precision_horz = 1, precision_vert = 2, size = 3
        }
      }
      cert  = { type = "CERT", data = { type = 1, key_tag = 1234, algorithm = 8, certificate = "TestCertificate==" } }
      ds    = { type = "DS", data = { key_tag = 1234, algorithm = 8, digest_type = 2, digest = "ABCDEF" } }
      sshfp = { type = "SSHFP", data = { algorithm = 1, type = 1, fingerprint = "ABCDEF" } }
      tlsa  = { type = "TLSA", data = { usage = 3, selector = 1, matching_type = 1, certificate = "ABCDEF" } }
    }
  }
  assert {
    condition = (
      jsonencode(cloudflare_dns_record.this["caa"].data.flags) == "0" &&
      jsonencode(cloudflare_dns_record.this["dnskey"].data.flags) == "257" &&
      jsonencode(cloudflare_dns_record.this["naptr"].data.flags) == "\"S\""
    )
    error_message = "Numeric and textual flags must retain their correct types within one map."
  }
  assert {
    condition = (
      cloudflare_dns_record.this["srv"].data.port == 5060 &&
      cloudflare_dns_record.this["srv"].data.target == "Sip.EXAMPLE.com." &&
      cloudflare_dns_record.this["loc"].data.altitude == 12.5 &&
      cloudflare_dns_record.this["cert"].data.key_tag == 1234 &&
      cloudflare_dns_record.this["ds"].data.digest_type == 2 &&
      cloudflare_dns_record.this["sshfp"].data.fingerprint == "ABCDEF" &&
      cloudflare_dns_record.this["tlsa"].data.usage == 3
    )
    error_message = "Structured record properties must pass through."
  }
}

run "direct_id_does_not_lookup" {
  command = plan
  variables {
    records = {
      relative = { name = "WWW.", type = "A", content = "192.0.2.1" }
      apex     = { name = "", type = "TXT", content = "apex" }
      full     = { full_name = "WWW.EXAMPLE.COM.", type = "AAAA", content = "2001:db8::1" }
    }
  }
  assert {
    condition = (
      length(data.cloudflare_zone.this) == 0 &&
      output.zone == null && output.zone_name == null &&
      cloudflare_dns_record.this["relative"].name == "www" &&
      cloudflare_dns_record.this["apex"].name == "@" &&
      cloudflare_dns_record.this["full"].name == "www.example.com"
    )
    error_message = "Direct zone IDs must bypass lookup and preserve relative-name support."
  }
}

run "advanced_filter" {
  command = plan
  variables {
    zone_id = null
    zone_filter = {
      name      = "equal:example.com"
      account   = { id = "0123456789abcdef0123456789abcdef", name = "contains_case_sensitive:Team" }
      direction = "asc"
      match     = "all"
      order     = "name"
      status    = "active"
      type      = ["full", "internal"]
    }
  }
  assert {
    condition = (
      data.cloudflare_zone.this[0].filter.name == "equal:example.com" &&
      data.cloudflare_zone.this[0].filter.account.name == "contains_case_sensitive:Team" &&
      data.cloudflare_zone.this[0].filter.type == tolist(["full", "internal"])
    )
    error_message = "Advanced filters must pass through without normalizing operators or case."
  }
}

run "disabled" {
  command = plan
  variables {
    create    = false
    zone_id   = null
    zone_name = "example.com"
    records   = { www = { type = "A", content = "192.0.2.1" } }
  }
  assert {
    condition = (
      length(cloudflare_dns_record.this) == 0 && length(data.cloudflare_zone.this) == 0 &&
      length(output.records) == 0 && output.zone_id == null && output.zone_name == null
    )
    error_message = "Disabled modules must create neither records nor zone lookups."
  }
}

run "reject_content_and_data" {
  command = plan
  variables {
    records = { bad = { type = "CAA", content = "0 issue example.com", data = { flags = 0, tag = "issue", value = "example.com" } } }
  }
  expect_failures = [var.records]
}

run "reject_missing_content_and_data" {
  command = plan
  variables {
    records = { bad = { type = "A" } }
  }
  expect_failures = [var.records]
}

run "reject_both_name_modes" {
  command = plan
  variables {
    records = { bad = { name = "www", full_name = "www.example.com", type = "A", content = "192.0.2.1" } }
  }
  expect_failures = [var.records]
}

run "reject_invalid_ttl" {
  command = plan
  variables {
    records = { bad = { type = "A", content = "192.0.2.1", ttl = 0 } }
  }
  expect_failures = [var.records]
}

run "reject_fractional_ttl" {
  command = plan
  variables {
    defaults = { ttl = 300.5 }
  }
  expect_failures = [var.defaults]
}

run "reject_proxied_fixed_ttl" {
  command = plan
  variables {
    defaults = { ttl = 300 }
    records  = { bad = { type = "A", content = "192.0.2.1", proxied = true } }
  }
  expect_failures = [cloudflare_dns_record.this]
}

run "reject_no_zone" {
  command = plan
  variables {
    zone_id = null
  }
  expect_failures = [output.zone_id]
}

run "reject_account_with_direct_id" {
  command = plan
  variables {
    account_id = "0123456789abcdef0123456789abcdef"
  }
  expect_failures = [output.zone_id]
}

run "reject_invalid_flags" {
  command = plan
  variables {
    records = { bad = { type = "CAA", data = { flags = "S", tag = "issue", value = "example.com" } } }
  }
  expect_failures = [var.records]
}

# Synthetic schema-only fixture: API-valid record-type combinations are covered
# separately by the individual record cases and the live integration workflow.
