mock_provider "cloudflare" {
  mock_resource "cloudflare_account_dns_settings_internal_view" {
    defaults = {
      created_time  = "2026-01-01T00:00:00Z"
      modified_time = "2026-01-02T00:00:00Z"
    }
  }
}

run "unmanaged_by_default" {
  command = plan
  assert {
    condition     = length(output.views) == 0
    error_message = "Empty views must not create resources or require an account."
  }
}

run "shared_zones_names_and_complete_outputs" {
  command = apply
  variables {
    account_id = "default-account"
    views = {
      corporate  = { name = "Corporate Clients", zones = ["apps-zone", "services-zone", "apps-zone"] }
      restricted = { zones = ["apps-zone"] }
      empty      = { account_id = "other-account", zones = [] }
    }
  }
  assert {
    condition = (
      output.views == cloudflare_account_dns_settings_internal_view.this &&
      output.views.corporate.account_id == "default-account" && output.views.corporate.name == "Corporate Clients" &&
      length(output.views.corporate.zones) == 2 && contains(output.views.corporate.zones, "apps-zone") &&
      contains(output.views.corporate.zones, "services-zone") && output.views.restricted.name == "restricted" &&
      contains(output.views.restricted.zones, "apps-zone") && length(output.views.empty.zones) == 0 &&
      output.views.empty.account_id == "other-account" && output.views.corporate.created_time == "2026-01-01T00:00:00Z" &&
      output.views.corporate.modified_time == "2026-01-02T00:00:00Z"
    )
    error_message = "Views must preserve names and computed metadata, deduplicate zone sets, allow shared zones and empty views, and honor account overrides."
  }
}

run "disabled" {
  command = plan
  variables {
    create = false
    views  = { unused = { zones = ["zone-id"] } }
  }
  assert {
    condition     = length(output.views) == 0
    error_message = "Disabled views must not require accounts or create resources."
  }
}

run "reject_missing_account" {
  command = plan
  variables {
    views = { invalid = { zones = [] } }
  }
  expect_failures = [cloudflare_account_dns_settings_internal_view.this]
}
