mock_provider "cloudflare" {
  mock_resource "cloudflare_dns_zone_transfers_incoming" {
    defaults = {
      soa_serial   = 2026010101
      checked_time = "2026-01-01T00:00:00Z"
    }
  }
  mock_resource "cloudflare_dns_zone_transfers_outgoing" {
    defaults = {
      soa_serial            = 2026010102
      last_transferred_time = "2026-01-02T00:00:00Z"
    }
  }
}

run "unmanaged_by_default" {
  command = plan
  assert {
    condition = (
      length(output.acls) == 0 && length(output.tsig_keys) == 0 && length(output.tsig_key_ids) == 0 &&
      length(output.peers) == 0 && length(output.incoming) == 0 && length(output.outgoing) == 0
    )
    error_message = "An empty invocation must not require an account or zone, or create any resources."
  }
}

run "managed_chain_and_complete_results" {
  command = apply
  variables {
    account_id = "0123456789abcdef0123456789abcdef"
    acls = {
      notify = { name = "Additional NOTIFY", ip_range = "192.0.2.0/24" }
    }
    tsig_keys = {
      primary = { name = "Exact.Key.Name.", algo = " HMAC-SHA256 ", secret = base64encode("test-only-transfer-secret") }
    }
    peers = {
      primary   = { name = "Primary server", ip = "192.0.2.1", port = 53, ixfr_enable = false, tsig_id = "primary" }
      secondary = { ip = "2001:db8::1", port = 5353, ixfr_enable = true, tsig_id = "external-tsig-id" }
    }
    incoming = {
      secondary_zone = {
        zone_id              = "023e105f4ecef8ad9ca31a8372d0c353"
        name                 = " EXAMPLE.COM. "
        peers                = ["primary", "external-peer-id"]
        auto_refresh_seconds = 3600
      }
    }
    outgoing = {
      primary_zone = {
        zone_id = "123e105f4ecef8ad9ca31a8372d0c353"
        name    = " PRIMARY.Example.NET. "
        peers   = ["secondary", "primary"]
      }
    }
  }
  assert {
    condition = (
      output.acls == cloudflare_dns_zone_transfers_acl.this && output.acls.notify.account_id == var.account_id &&
      output.acls.notify.name == "Additional NOTIFY" && output.acls.notify.ip_range == "192.0.2.0/24" &&
      output.tsig_keys == cloudflare_dns_zone_transfers_tsig.this && output.tsig_keys.primary.account_id == var.account_id &&
      output.tsig_keys.primary.name == "Exact.Key.Name." && output.tsig_keys.primary.algo == "hmac-sha256" &&
      output.tsig_keys.primary.secret == var.tsig_keys.primary.secret && output.tsig_key_ids.primary == output.tsig_keys.primary.id
    )
    error_message = "ACLs and TSIG keys must expose complete results, normalize algorithms, and preserve key names and secret material."
  }
  assert {
    condition = (
      output.peers == cloudflare_dns_zone_transfers_peer.this &&
      output.peers.primary.tsig_id == output.tsig_key_ids.primary && output.peers.primary.account_id == var.account_id &&
      output.peers.primary.ip == "192.0.2.1" && output.peers.primary.port == 53 && !output.peers.primary.ixfr_enable &&
      output.peers.primary.name == "Primary server" && output.peers.secondary.name == "secondary" &&
      output.peers.secondary.ip == "2001:db8::1" && output.peers.secondary.port == 5353 && output.peers.secondary.ixfr_enable &&
      output.peers.secondary.tsig_id == "external-tsig-id"
    )
    error_message = "Peer keys must resolve TSIG IDs while preserving literal IDs, IPv4/IPv6 addresses, ports, names, and explicit false values."
  }
  assert {
    condition = (
      output.incoming == cloudflare_dns_zone_transfers_incoming.this && output.outgoing == cloudflare_dns_zone_transfers_outgoing.this &&
      output.incoming.secondary_zone.zone_id == "023e105f4ecef8ad9ca31a8372d0c353" &&
      output.incoming.secondary_zone.name == "example.com" && output.incoming.secondary_zone.auto_refresh_seconds == 3600 &&
      contains(output.incoming.secondary_zone.peers, output.peers.primary.id) && contains(output.incoming.secondary_zone.peers, "external-peer-id") &&
      output.outgoing.primary_zone.zone_id == "123e105f4ecef8ad9ca31a8372d0c353" && output.outgoing.primary_zone.name == "primary.example.net" &&
      contains(output.outgoing.primary_zone.peers, output.peers.secondary.id) && contains(output.outgoing.primary_zone.peers, output.peers.primary.id) &&
      output.incoming.secondary_zone.soa_serial == 2026010101 && output.incoming.secondary_zone.checked_time == "2026-01-01T00:00:00Z" &&
      output.outgoing.primary_zone.soa_serial == 2026010102 && output.outgoing.primary_zone.last_transferred_time == "2026-01-02T00:00:00Z"
    )
    error_message = "Transfers must resolve managed/external peers, normalize zone names, and retain complete computed transfer status."
  }
}

run "per_entry_accounts_and_literal_peer_ids" {
  command = apply
  variables {
    account_id = "default-account"
    acls       = { ipv6 = { account_id = "acl-account", ip_range = "2001:db8::/64" } }
    tsig_keys  = { shared = { account_id = "key-account", algo = "hmac-sha512", secret = base64encode("test-only-secondary-secret") } }
    peers      = { literal = { account_id = "peer-account", tsig_id = "existing-id", ixfr_enable = false, port = 0 } }
    incoming   = { existing = { zone_id = "zone-id", name = "example.com", peers = ["existing-peer"], auto_refresh_seconds = 0 } }
    outgoing   = { cleared = { zone_id = "other-zone-id", name = "example.net", peers = [] } }
  }
  assert {
    condition = (
      output.acls.ipv6.account_id == "acl-account" && output.acls.ipv6.name == "ipv6" &&
      output.tsig_keys.shared.account_id == "key-account" && output.tsig_keys.shared.name == "shared" &&
      output.peers.literal.account_id == "peer-account" && output.peers.literal.tsig_id == "existing-id" &&
      !output.peers.literal.ixfr_enable && output.peers.literal.port == 0 && output.incoming.existing.auto_refresh_seconds == 0 &&
      contains(output.incoming.existing.peers, "existing-peer") && length(output.outgoing.cleared.peers) == 0
    )
    error_message = "Account overrides, literal IDs, zero values, and explicit empty peer sets must pass through for upstream validation."
  }
}

run "transfers_without_account_resources" {
  command = plan
  variables {
    incoming = { secondary = { zone_id = "zone-id", name = "example.com", peers = ["existing-peer"] } }
  }
  assert {
    condition = (
      length(output.tsig_keys) == 0 && length(output.peers) == 0 && length(output.acls) == 0 &&
      contains(output.incoming.secondary.peers, "existing-peer") && output.incoming.secondary.name == "example.com"
    )
    error_message = "Referencing existing peers must not require an account or acquire ownership of account resources."
  }
}

run "global_disable_suppresses_resources" {
  command = plan
  variables {
    create    = false
    acls      = { notify = { ip_range = "192.0.2.0/24" } }
    tsig_keys = { key = { algo = "hmac-sha256", secret = base64encode("test-only-disabled-secret") } }
    peers     = { primary = { tsig_id = "key" } }
    incoming  = { secondary = { zone_id = "zone-id", name = "example.com", peers = ["primary"] } }
    outgoing  = { primary = { zone_id = "other-zone-id", name = "example.net", peers = ["primary"] } }
  }
  assert {
    condition = (
      length(output.acls) == 0 && length(output.tsig_keys) == 0 && length(output.tsig_key_ids) == 0 &&
      length(output.peers) == 0 && length(output.incoming) == 0 && length(output.outgoing) == 0
    )
    error_message = "Global disable must suppress the complete chain without requiring accounts."
  }
}

run "reject_missing_acl_account" {
  command = plan
  variables {
    acls = { notify = { ip_range = "192.0.2.0/24" } }
  }
  expect_failures = [cloudflare_dns_zone_transfers_acl.this]
}

run "reject_missing_tsig_account" {
  command = plan
  variables {
    tsig_keys = { primary = { algo = "hmac-sha256", secret = base64encode("test-only-missing-account") } }
  }
  expect_failures = [cloudflare_dns_zone_transfers_tsig.this]
}

run "reject_missing_peer_account" {
  command = plan
  variables {
    peers = { primary = {} }
  }
  expect_failures = [cloudflare_dns_zone_transfers_peer.this]
}

run "reject_duplicate_incoming_zone" {
  command = plan
  variables {
    incoming = {
      first  = { zone_id = "same-id", name = "example.com", peers = [] }
      second = { zone_id = "same-id", name = "example.com", peers = [] }
    }
  }
  expect_failures = [var.incoming]
}

run "reject_duplicate_outgoing_zone" {
  command = plan
  variables {
    outgoing = {
      first  = { zone_id = "same-id", name = "example.com", peers = [] }
      second = { zone_id = "same-id", name = "example.com", peers = [] }
    }
  }
  expect_failures = [var.outgoing]
}
