mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = {
      id   = "023e105f4ecef8ad9ca31a8372d0c353"
      name = "example.com"
    }
  }
  mock_resource "cloudflare_dns_record" {
    defaults = {
      id                  = "record-id"
      proxiable           = true
      meta                = "{\"test\":true}"
      created_on          = "2026-01-01T00:00:00Z"
      modified_on         = "2026-01-01T00:00:00Z"
      tags_modified_on    = "2026-01-01T00:00:00Z"
      comment_modified_on = "2026-01-01T00:00:00Z"
    }
  }
}

run "whole_objects_preserve_computed_fields" {
  command = apply
  variables {
    zone_name = "example.com"
    records = {
      www = { type = "A", content = "192.0.2.1", proxied = false }
    }
  }
  assert {
    condition = (
      output.records["www"].id == "record-id" &&
      output.records["www"].proxied == false &&
      output.records["www"].proxiable == true &&
      jsondecode(output.records["www"].meta).test == true &&
      output.records["www"].created_on == "2026-01-01T00:00:00Z" &&
      output.records["www"].comment_modified_on == "2026-01-01T00:00:00Z" &&
      output.records["www"].tags_modified_on == "2026-01-01T00:00:00Z" &&
      output.zone.id == output.zone_id
    )
    error_message = "Whole-object outputs must expose computed properties and distinguish proxy capability from enabled state."
  }
}

run "reject_multiple_zone_selectors" {
  command = plan
  variables {
    zone_id   = "023e105f4ecef8ad9ca31a8372d0c353"
    zone_name = "example.com"
  }
  expect_failures = [data.cloudflare_zone.this, output.zone_id]
}
