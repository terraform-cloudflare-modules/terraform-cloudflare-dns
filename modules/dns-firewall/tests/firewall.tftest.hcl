mock_provider "cloudflare" {
  mock_resource "cloudflare_dns_firewall" {
    defaults = {
      dns_firewall_ips = ["198.51.100.1", "198.51.100.2"]
      modified_on      = "2026-01-01T00:00:00Z"
    }
  }
}

run "unmanaged_by_default" {
  command = plan
  assert {
    condition     = length(output.clusters) == 0
    error_message = "Empty clusters must not create resources or require an account."
  }
}

run "all_fields_and_complete_outputs" {
  command = apply
  variables {
    account_id = "default-account"
    clusters = {
      primary = {
        name                   = "External Authoritative DNS"
        attack_mitigation      = { enabled = false, only_when_upstream_unhealthy = false }
        deprecate_any_requests = false
        dns_firewall_ip_count  = 2
        ecs_fallback           = false
        maximum_cache_ttl      = 3600
        minimum_cache_ttl      = 30
        negative_cache_ttl     = 30
        ratelimit              = 1000
        retries                = 0
        upstream_ips           = ["192.0.2.1", "2001:db8::1"]
      }
      other = {
        account_id             = "other-account"
        upstream_ips           = ["192.0.2.2"]
        attack_mitigation      = { enabled = true, only_when_upstream_unhealthy = true }
        deprecate_any_requests = true
        ecs_fallback           = true
      }
    }
  }
  assert {
    condition = (
      output.clusters == cloudflare_dns_firewall.this && output.clusters.primary.account_id == "default-account" &&
      output.clusters.primary.name == "External Authoritative DNS" && output.clusters.other.name == "other" &&
      output.clusters.other.account_id == "other-account" &&
      !output.clusters.primary.attack_mitigation.enabled && !output.clusters.primary.attack_mitigation.only_when_upstream_unhealthy &&
      !output.clusters.primary.deprecate_any_requests && !output.clusters.primary.ecs_fallback &&
      output.clusters.primary.dns_firewall_ip_count == 2 && output.clusters.primary.maximum_cache_ttl == 3600 &&
      output.clusters.primary.minimum_cache_ttl == 30 && output.clusters.primary.negative_cache_ttl == 30 &&
      output.clusters.primary.ratelimit == 1000 && output.clusters.primary.retries == 0 &&
      contains(output.clusters.primary.upstream_ips, "192.0.2.1") && contains(output.clusters.primary.upstream_ips, "2001:db8::1") &&
      contains(output.clusters.primary.dns_firewall_ips, "198.51.100.1") && output.clusters.primary.modified_on == "2026-01-01T00:00:00Z" &&
      output.clusters.other.attack_mitigation.enabled && output.clusters.other.attack_mitigation.only_when_upstream_unhealthy &&
      output.clusters.other.deprecate_any_requests && output.clusters.other.ecs_fallback && output.clusters.other.ratelimit == null
    )
    error_message = "Firewall clusters must expose complete outputs and all controls, retaining explicit false/zero values, account overrides, and provider-assigned addresses."
  }
}

run "empty_mitigation" {
  command = plan
  variables {
    clusters = { empty = { account_id = "account-id", upstream_ips = ["192.0.2.1"], attack_mitigation = {} } }
  }
  assert {
    condition     = output.clusters.empty.attack_mitigation != null && contains(output.clusters.empty.upstream_ips, "192.0.2.1")
    error_message = "An empty mitigation object must be preserved alongside a valid upstream server."
  }
}

run "disabled" {
  command = plan
  variables {
    create   = false
    clusters = { unused = { upstream_ips = ["192.0.2.1"] } }
  }
  assert {
    condition     = length(output.clusters) == 0
    error_message = "Disabled clusters must not require accounts or create resources."
  }
}

run "reject_missing_account" {
  command = plan
  variables {
    clusters = { invalid = { upstream_ips = ["192.0.2.1"] } }
  }
  expect_failures = [cloudflare_dns_firewall.this]
}
