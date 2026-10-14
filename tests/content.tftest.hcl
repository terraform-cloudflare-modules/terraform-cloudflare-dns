mock_provider "cloudflare" {}

variables {
  zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "mixed_scalar_list_and_structured_payloads" {
  command = plan
  variables {
    records = {
      website = { name = "www", type = "A", content = "192.0.2.10" }
      servers = { name = "www", type = "A", content = ["192.0.2.11", "192.0.2.12"] }
      mail = {
        name = "@"
        type = " mx "
        content = [
          "1 aspmx.l.google.com",
          "5 alt1.aspmx.l.google.com",
          "5 alt2.aspmx.l.google.com",
          "10 alt3.aspmx.l.google.com",
          "  10\talt4.aspmx.l.google.com  ",
        ]
      }
      caa   = { name = "@", type = "CAA", data = { flags = 0, tag = "issue", value = "letsencrypt.org" } }
      naptr = { name = "@", type = "NAPTR", data = { flags = "S", order = 10, preference = 20, service = "SIP+D2U", regex = "", replacement = "_sip._udp.example.com." } }
      txt   = { name = "_verify", type = "TXT", content = ["  Mixed Case  ", "10 this is not MX"] }
    }
  }
  assert {
    condition = (
      length(output.records) == 12 &&
      output.records["website"].content == "192.0.2.10" &&
      output.records["servers[0]"].name == "www" &&
      output.records["servers[1]"].content == "192.0.2.12" &&
      output.records["caa"].data.flags == 0 && output.records["naptr"].data.flags == "S"
    )
    error_message = "Scalar and structured addresses must stay unchanged while lists expand independently."
  }
  assert {
    condition = (
      output.records["mail[0]"].name == "@" &&
      output.records["mail[0]"].content == "aspmx.l.google.com" && output.records["mail[0]"].priority == 1 &&
      output.records["mail[1]"].priority == 5 && output.records["mail[2]"].priority == 5 &&
      output.records["mail[3]"].priority == 10 && output.records["mail[4]"].priority == 10 &&
      output.records["mail[4]"].content == "alt4.aspmx.l.google.com"
    )
    error_message = "MX priority prefixes must be parsed per value, including repeated whitespace."
  }
  assert {
    condition     = output.records["txt[0]"].content == "  Mixed Case  " && output.records["txt[1]"].content == "10 this is not MX"
    error_message = "Non-MX payloads must remain byte-for-byte unchanged."
  }
}

run "inherit_and_override_priority_and_defaults" {
  command = plan
  variables {
    defaults = { ttl = 3600, comment = "shared", tags = ["owner:mail"] }
    records = {
      mail = {
        name     = "@"
        type     = "MX"
        priority = 20
        content  = ["mx1.example.net", "0 mx2.example.net", "65535 mx3.example.net"]
        comment  = ""
        tags     = []
      }
    }
  }
  assert {
    condition = (
      output.records["mail[0]"].priority == 20 && output.records["mail[1]"].priority == 0 && output.records["mail[2]"].priority == 65535 &&
      alltrue([for record in output.records : record.ttl == 3600 && record.comment == "" && length(record.tags) == 0])
    )
    error_message = "Each value must inherit group settings, with explicit MX prefixes overriding group priority."
  }
}

run "scalar_mx_is_not_parsed" {
  command = plan
  variables {
    records = { mail = { name = "@", type = "MX", content = "mx.example.net", priority = 10 } }
  }
  assert {
    condition     = output.records["mail"].content == "mx.example.net" && output.records["mail"].priority == 10
    error_message = "Scalar MX behavior and addresses must remain unchanged."
  }
}

run "empty_lists_and_disabled_groups" {
  command = plan
  variables {
    records = { empty = { name = "www", type = "A", content = [] } }
  }
  assert {
    condition     = length(output.records) == 0
    error_message = "An empty list must create no records."
  }
}

run "disabled_lists" {
  command = plan
  variables {
    create  = false
    records = { mail = { name = "@", type = "MX", content = ["10 mx.example.net"] } }
  }
  assert {
    condition     = length(output.records) == 0
    error_message = "Disabling the module must suppress all expanded records."
  }
}

run "reject_mx_without_priority" {
  command = plan
  variables {
    records = { mail = { name = "@", type = "MX", content = ["mx.example.net"] } }
  }
  expect_failures = [var.records]
}

run "reject_invalid_priority" {
  command = plan
  variables {
    records = { mail = { name = "@", type = "MX", content = ["65536 mx.example.net"] } }
  }
  expect_failures = [var.records]
}

run "reject_extra_mx_tokens" {
  command = plan
  variables {
    records = { mail = { name = "@", type = "MX", content = ["10 mx.example.net extra"] } }
  }
  expect_failures = [var.records]
}

run "reject_fractional_mx_priority" {
  command = plan
  variables {
    records = { mail = { name = "@", type = "MX", content = ["1.5 mx.example.net"] } }
  }
  expect_failures = [var.records]
}

run "reject_object_content" {
  command = plan
  variables {
    records = { address = { name = "www", type = "A", content = { value = "192.0.2.1" } } }
  }
  expect_failures = [var.records]
}

run "reject_null_list_value" {
  command = plan
  variables {
    records = { address = { name = "www", type = "A", content = [null] } }
  }
  expect_failures = [var.records]
}

run "reject_expansion_key_collision" {
  command = plan
  variables {
    records = {
      address      = { name = "www", type = "A", content = ["192.0.2.1"] }
      "address[0]" = { name = "www", type = "A", content = "192.0.2.2" }
    }
  }
  expect_failures = [var.records]
}

run "list_initial" {
  command = apply
  module {
    source = "./tests/fixtures/content"
  }
  variables {
    records = {
      address = { name = "www", type = "A", content = ["192.0.2.1", "192.0.2.2"] }
      scalar  = { name = "api", type = "A", content = "192.0.2.3" }
    }
  }
}

run "appending_preserves_existing_record_ids" {
  command = apply
  module {
    source = "./tests/fixtures/content"
  }
  variables {
    previous_records = run.list_initial.records
    records = {
      address = { name = "www", type = "A", content = ["192.0.2.1", "192.0.2.2", "192.0.2.4"] }
      scalar  = { name = "api", type = "A", content = "192.0.2.3" }
    }
  }
  assert {
    condition = (
      output.previous_ids_preserved &&
      output.records["address[2]"].content == "192.0.2.4"
    )
    error_message = "Appending a value must retain existing list and scalar resource identities."
  }
}
