mock_provider "cloudflare" {
  mock_resource "cloudflare_load_balancer_monitor_group" {
    defaults = { created_on = "2026-01-01T00:00:00Z" }
  }
}

run "unmanaged_by_default" {
  command = plan
  assert {
    condition     = length(output.groups) == 0
    error_message = "Empty groups must not create resources or require an account."
  }
}

run "members_and_complete_outputs" {
  command = apply
  variables {
    account_id = "default-account"
    groups = {
      critical = {
        description = "API and Login"
        members = [
          { monitor_id = "api-monitor", enabled = true, monitoring_only = false, must_be_healthy = true },
          { monitor_id = "observer-monitor", enabled = false, monitoring_only = true, must_be_healthy = false },
        ]
      }
      overridden = {
        account_id  = "other-account"
        description = ""
        members     = [{ monitor_id = "external-id", enabled = true, monitoring_only = false, must_be_healthy = false }]
      }
    }
  }
  assert {
    condition = (
      output.groups == cloudflare_load_balancer_monitor_group.this && output.groups.critical.account_id == "default-account" &&
      output.groups.critical.description == "API and Login" && output.groups.critical.created_on == "2026-01-01T00:00:00Z" &&
      output.groups.overridden.account_id == "other-account" && output.groups.overridden.description == "" &&
      length(output.groups.critical.members) == 2 &&
      alltrue([for member in output.groups.critical.members : member.monitor_id == "api-monitor" ?
        (member.enabled && !member.monitoring_only && member.must_be_healthy) :
        (member.monitor_id == "observer-monitor" && !member.enabled && member.monitoring_only && !member.must_be_healthy)
      ])
    )
    error_message = "Group outputs must retain IDs/timestamps, account overrides, descriptions, and every member flag without depending on set order."
  }
}

run "empty_members_pass_through" {
  command = plan
  variables {
    groups = { cleared = { account_id = "account-id", description = "Empty membership", members = [] } }
  }
  assert {
    condition     = length(output.groups.cleared.members) == 0
    error_message = "Explicit empty membership must pass through for upstream validation."
  }
}

run "disabled" {
  command = plan
  variables {
    create = false
    groups = { unused = { description = "unused", members = [] } }
  }
  assert {
    condition     = length(output.groups) == 0
    error_message = "Disabled groups must not require accounts or create resources."
  }
}

run "reject_missing_account" {
  command = plan
  variables {
    groups = { invalid = { description = "invalid", members = [] } }
  }
  expect_failures = [cloudflare_load_balancer_monitor_group.this]
}
