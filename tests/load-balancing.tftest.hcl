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

run "unmanaged_by_default" {
  command = plan
  assert {
    condition = (
      length(output.load_balancers) == 0 && length(output.load_balancer_pools) == 0 &&
      length(output.load_balancer_monitors) == 0
    )
    error_message = "Existing callers must not acquire load balancing resources."
  }
}

run "managed_chain_and_geo_steering" {
  command = apply
  variables {
    account_id = "0123456789abcdef0123456789abcdef"
    load_balancer_monitors = {
      https = {
        type             = " HTTPS "
        method           = " get "
        path             = "/Health"
        header           = { Host = ["Api.Example.COM"], X-Probe = ["Preserve Case"] }
        description      = "Health check"
        expected_body    = "Healthy"
        expected_codes   = "2xx"
        allow_insecure   = false
        follow_redirects = false
        consecutive_up   = 2
        consecutive_down = 3
        interval         = 60
        timeout          = 5
        retries          = 0
        port             = 443
        probe_zone       = "example.com"
      }
    }
    load_balancer_pools = {
      eu = {
        name            = "Europe"
        monitor         = "https"
        check_regions   = ["WEU"]
        description     = "European origins"
        enabled         = false
        latitude        = 50
        longitude       = 0
        minimum_origins = 1
        load_shedding = {
          default_percent = 0
          default_policy  = "random"
          session_percent = 0
          session_policy  = "hash"
        }
        origin_steering    = { policy = "random" }
        notification_email = ""
        notification_filter = {
          origin = { disable = false, healthy = false }
          pool   = { disable = true, healthy = false }
        }
        origins = [{
          name               = "eu-primary"
          address            = "192.0.2.10"
          enabled            = false
          flatten_cname      = false
          header             = { host = ["Api.Example.COM"] }
          port               = 443
          virtual_network_id = "0123456789abcdef0123456789abcdef"
          weight             = 0
        }]
      }
      us = {
        monitor = "https"
        origins = [{ name = "us-primary", address = "192.0.2.20" }]
      }
    }
    load_balancers = {
      api = {
        full_name       = " API.Example.COM. "
        default_pools   = ["eu", "us"]
        fallback_pool   = "us"
        country_pools   = { DE = ["eu", "us"] }
        region_pools    = { ENAM = ["us"] }
        pop_pools       = { LHR = ["eu"] }
        steering_policy = " GEO "
        ttl             = 60
        enabled         = false
        description     = ""
      }
    }
  }
  assert {
    condition = (
      output.load_balancer_monitors.https == cloudflare_load_balancer_monitor.this["https"] &&
      output.load_balancer_monitors.https.account_id == var.account_id &&
      output.load_balancer_monitors.https.type == "https" && output.load_balancer_monitors.https.method == "GET" &&
      output.load_balancer_monitors.https.path == "/Health" &&
      output.load_balancer_monitors.https.header["X-Probe"][0] == "Preserve Case" &&
      !output.load_balancer_monitors.https.allow_insecure && !output.load_balancer_monitors.https.follow_redirects &&
      output.load_balancer_monitors.https.retries == 0 && output.load_balancer_monitors.https.expected_body == "Healthy" &&
      output.load_balancer_monitors.https.expected_codes == "2xx" && output.load_balancer_monitors.https.consecutive_up == 2 &&
      output.load_balancer_monitors.https.consecutive_down == 3 && output.load_balancer_monitors.https.interval == 60 &&
      output.load_balancer_monitors.https.timeout == 5 && output.load_balancer_monitors.https.port == 443 &&
      output.load_balancer_monitors.https.probe_zone == "example.com"
    )
    error_message = "Monitors must expose complete results, inherit account IDs, normalize enums, and preserve probe data and explicit zero/false values."
  }
  assert {
    condition = (
      output.load_balancer_pools.eu == cloudflare_load_balancer_pool.this["eu"] &&
      output.load_balancer_pools.eu.account_id == var.account_id && output.load_balancer_pools.eu.name == "Europe" &&
      output.load_balancer_pools.us.name == "us" &&
      output.load_balancer_pools.eu.monitor == output.load_balancer_monitors.https.id &&
      output.load_balancer_pools.eu.origins[0].header.host[0] == "Api.Example.COM" &&
      !output.load_balancer_pools.eu.origins[0].enabled && !output.load_balancer_pools.eu.origins[0].flatten_cname &&
      output.load_balancer_pools.eu.origins[0].weight == 0 && output.load_balancer_pools.eu.origins[0].port == 443 &&
      output.load_balancer_pools.eu.origins[0].virtual_network_id == "0123456789abcdef0123456789abcdef" &&
      output.load_balancer_pools.eu.load_shedding.default_percent == 0 && output.load_balancer_pools.eu.load_shedding.session_percent == 0 &&
      output.load_balancer_pools.eu.load_shedding.default_policy == "random" && output.load_balancer_pools.eu.load_shedding.session_policy == "hash" &&
      !output.load_balancer_pools.eu.notification_filter.origin.disable && !output.load_balancer_pools.eu.notification_filter.origin.healthy &&
      output.load_balancer_pools.eu.notification_filter.pool.disable && !output.load_balancer_pools.eu.notification_filter.pool.healthy &&
      output.load_balancer_pools.eu.notification_email == "" && output.load_balancer_pools.eu.origin_steering.policy == "random" &&
      output.load_balancer_pools.eu.longitude == 0 && output.load_balancer_pools.eu.latitude == 50 &&
      output.load_balancer_pools.eu.minimum_origins == 1 && output.load_balancer_pools.eu.check_regions[0] == "WEU" && !output.load_balancer_pools.eu.enabled
    )
    error_message = "Pools must preserve all nested settings and resolve managed monitor keys without changing resource identity."
  }
  assert {
    condition = (
      output.load_balancers.api == cloudflare_load_balancer.this["api"] &&
      output.load_balancers.api.zone_id == var.zone_id && output.load_balancers.api.name == "api.example.com" &&
      !output.load_balancers.api.proxied && !output.load_balancers.api.enabled && output.load_balancers.api.description == "" &&
      output.load_balancers.api.steering_policy == "geo" && output.load_balancers.api.ttl == 60 &&
      output.load_balancers.api.default_pools[0] == output.load_balancer_pools.eu.id &&
      output.load_balancers.api.default_pools[1] == output.load_balancer_pools.us.id &&
      output.load_balancers.api.fallback_pool == output.load_balancer_pools.us.id &&
      output.load_balancers.api.country_pools["DE"][0] == output.load_balancer_pools.eu.id &&
      output.load_balancers.api.country_pools["DE"][1] == output.load_balancer_pools.us.id &&
      output.load_balancers.api.region_pools["ENAM"][0] == output.load_balancer_pools.us.id &&
      output.load_balancers.api.pop_pools["LHR"][0] == output.load_balancer_pools.eu.id
    )
    error_message = "DNS-only load balancers must resolve all geographic mappings and preserve failover order and whole outputs."
  }
}

run "rule_overrides_and_weighted_steering" {
  command = apply
  variables {
    load_balancer_pools = {
      primary = {
        account_id = "0123456789abcdef0123456789abcdef"
        origins    = [{ name = "primary", address = "192.0.2.1" }]
      }
    }
    load_balancers = {
      weighted = {
        full_name            = "weighted.example.com"
        default_pools        = ["primary", "external-pool-id"]
        fallback_pool        = "external-pool-id"
        proxied              = true
        networks             = ["standard"]
        adaptive_routing     = { failover_across_pools = false }
        location_strategy    = { mode = "resolver_ip", prefer_ecs = "always" }
        random_steering      = { default_weight = 0, pool_weights = { primary = 0.75, external-pool-id = 0.25 } }
        session_affinity     = "cookie"
        session_affinity_ttl = 1800
        session_affinity_attributes = {
          drain_duration         = 0
          headers                = ["X-Session"]
          require_all_headers    = false
          samesite               = "Auto"
          secure                 = "Auto"
          zero_downtime_failover = "none"
        }
        rules = [
          {
            name       = "Override"
            condition  = "http.request.uri.path contains \"/CaseSensitive\""
            disabled   = false
            priority   = 0
            terminates = false
            overrides = {
              default_pools     = ["primary", "external-pool-id"]
              fallback_pool     = "primary"
              country_pools     = { DE = ["primary"] }
              region_pools      = { WEU = ["external-pool-id", "primary"] }
              pop_pools         = { LHR = ["primary"] }
              random_steering   = { default_weight = 0, pool_weights = { primary = 0, external-pool-id = 1 } }
              adaptive_routing  = { failover_across_pools = false }
              location_strategy = { mode = "pop", prefer_ecs = "never" }
              session_affinity  = "none"
              session_affinity_attributes = {
                drain_duration         = 0
                headers                = []
                require_all_headers    = false
                samesite               = "Lax"
                secure                 = "Never"
                zero_downtime_failover = "none"
              }
              session_affinity_ttl = 0
              steering_policy      = "random"
              ttl                  = 120
            }
          },
          {
            name           = "Response"
            fixed_response = { content_type = "text/plain", location = "https://example.com/Case", message_body = "Exact Body", status_code = 302 }
          },
          { name = "Empty overrides", overrides = { country_pools = {}, default_pools = [], random_steering = { pool_weights = {} } } }
        ]
      }
    }
  }
  assert {
    condition = (
      output.load_balancers.weighted.proxied && output.load_balancers.weighted.default_pools[1] == "external-pool-id" &&
      output.load_balancers.weighted.fallback_pool == "external-pool-id" && output.load_balancers.weighted.networks[0] == "standard" &&
      output.load_balancers.weighted.random_steering.pool_weights[output.load_balancer_pools.primary.id] == 0.75 &&
      output.load_balancers.weighted.random_steering.pool_weights["external-pool-id"] == 0.25 &&
      output.load_balancers.weighted.random_steering.default_weight == 0 &&
      output.load_balancers.weighted.location_strategy.mode == "resolver_ip" &&
      output.load_balancers.weighted.location_strategy.prefer_ecs == "always" &&
      !output.load_balancers.weighted.adaptive_routing.failover_across_pools &&
      output.load_balancers.weighted.session_affinity == "cookie" && output.load_balancers.weighted.session_affinity_ttl == 1800 &&
      output.load_balancers.weighted.session_affinity_attributes.drain_duration == var.load_balancers.weighted.session_affinity_attributes.drain_duration &&
      tolist(output.load_balancers.weighted.session_affinity_attributes.headers) == tolist(var.load_balancers.weighted.session_affinity_attributes.headers) &&
      output.load_balancers.weighted.session_affinity_attributes.require_all_headers == var.load_balancers.weighted.session_affinity_attributes.require_all_headers &&
      output.load_balancers.weighted.session_affinity_attributes.samesite == var.load_balancers.weighted.session_affinity_attributes.samesite &&
      output.load_balancers.weighted.session_affinity_attributes.secure == var.load_balancers.weighted.session_affinity_attributes.secure &&
      output.load_balancers.weighted.session_affinity_attributes.zero_downtime_failover == var.load_balancers.weighted.session_affinity_attributes.zero_downtime_failover
    )
    error_message = "Weighted and proxied settings must remain configurable, including literal external pool IDs and all affinity fields."
  }
  assert {
    condition = (
      length(output.load_balancers.weighted.rules) == 3 &&
      output.load_balancers.weighted.rules[0].condition == "http.request.uri.path contains \"/CaseSensitive\"" &&
      !output.load_balancers.weighted.rules[0].disabled && !output.load_balancers.weighted.rules[0].terminates &&
      output.load_balancers.weighted.rules[0].priority == 0 &&
      output.load_balancers.weighted.rules[0].overrides.default_pools[0] == output.load_balancer_pools.primary.id &&
      output.load_balancers.weighted.rules[0].overrides.default_pools[1] == "external-pool-id" &&
      output.load_balancers.weighted.rules[0].overrides.fallback_pool == output.load_balancer_pools.primary.id &&
      output.load_balancers.weighted.rules[0].overrides.country_pools["DE"][0] == output.load_balancer_pools.primary.id &&
      output.load_balancers.weighted.rules[0].overrides.region_pools["WEU"][0] == "external-pool-id" &&
      output.load_balancers.weighted.rules[0].overrides.pop_pools["LHR"][0] == output.load_balancer_pools.primary.id &&
      output.load_balancers.weighted.rules[0].overrides.random_steering.pool_weights[output.load_balancer_pools.primary.id] == 0 &&
      output.load_balancers.weighted.rules[0].overrides.random_steering.default_weight == 0 &&
      output.load_balancers.weighted.rules[0].overrides.adaptive_routing.failover_across_pools == false &&
      output.load_balancers.weighted.rules[0].overrides.location_strategy.mode == "pop" &&
      output.load_balancers.weighted.rules[0].overrides.location_strategy.prefer_ecs == "never" &&
      output.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.drain_duration == var.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.drain_duration &&
      length(output.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.headers) == 0 &&
      output.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.require_all_headers == var.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.require_all_headers &&
      output.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.samesite == var.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.samesite &&
      output.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.secure == var.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.secure &&
      output.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.zero_downtime_failover == var.load_balancers.weighted.rules[0].overrides.session_affinity_attributes.zero_downtime_failover &&
      output.load_balancers.weighted.rules[0].overrides.session_affinity == "none" &&
      output.load_balancers.weighted.rules[0].overrides.session_affinity_ttl == 0 &&
      output.load_balancers.weighted.rules[0].overrides.steering_policy == "random" && output.load_balancers.weighted.rules[0].overrides.ttl == 120 &&
      output.load_balancers.weighted.rules[1].fixed_response == var.load_balancers.weighted.rules[1].fixed_response &&
      length(output.load_balancers.weighted.rules[2].overrides.country_pools) == 0 &&
      length(output.load_balancers.weighted.rules[2].overrides.default_pools) == 0 &&
      length(output.load_balancers.weighted.rules[2].overrides.random_steering.pool_weights) == 0
    )
    error_message = "Ordered heterogeneous rules must preserve all settings, empty overrides, response data, and resolved pool references."
  }
}

run "lookup_names_and_external_resources" {
  command = plan
  variables {
    zone_id   = null
    zone_name = "example.com"
    load_balancers = {
      api      = { name = " API. ", default_pools = ["existing-id"], fallback_pool = "existing-id" }
      root     = { name = "@", default_pools = ["existing-id"], fallback_pool = "existing-id" }
      inferred = { default_pools = ["existing-id"], fallback_pool = "existing-id" }
    }
  }
  assert {
    condition = (
      output.load_balancers.api.name == "api.example.com" && output.load_balancers.root.name == "example.com" &&
      output.load_balancers.inferred.name == "inferred.example.com" && output.load_balancers.api.default_pools[0] == "existing-id" &&
      length(output.load_balancer_pools) == 0 && length(output.load_balancer_monitors) == 0 && length(output.records) == 0
    )
    error_message = "Lookup names must normalize consistently without taking ownership of referenced pools or monitors."
  }
}

run "account_overrides_and_empty_settings" {
  command = plan
  variables {
    zone_id     = null
    zone_filter = { name = "example.com", account = { id = "lookup-account" } }
    account_id  = "default-account"
    load_balancer_monitors = {
      overridden = { account_id = "monitor-account", header = {}, description = "" }
    }
    load_balancer_pools = {
      overridden = {
        account_id          = "pool-account"
        origins             = [{ address = "192.0.2.1", header = { host = [] } }]
        monitor             = "external-monitor-id"
        monitor_group       = "external-group-id"
        health_sources      = ["regional", "global"]
        check_regions       = ["WEU"] # Regional health requires at least one region.
        notification_filter = {}
        load_shedding       = {}
        origin_steering     = {}
      }
    }
  }
  assert {
    condition = (
      output.load_balancer_monitors.overridden.account_id == "monitor-account" &&
      length(output.load_balancer_monitors.overridden.header) == 0 && output.load_balancer_monitors.overridden.description == "" &&
      output.load_balancer_pools.overridden.account_id == "pool-account" && output.load_balancer_pools.overridden.monitor == "external-monitor-id" &&
      output.load_balancer_pools.overridden.monitor_group == "external-group-id" &&
      output.load_balancer_pools.overridden.health_sources == tolist(["regional", "global"]) &&
      length(output.load_balancer_pools.overridden.origins[0].header.host) == 0 &&
      output.load_balancer_pools.overridden.check_regions == tolist(["WEU"]) && output.load_balancer_pools.overridden.notification_filter != null &&
      output.load_balancer_pools.overridden.load_shedding != null && output.load_balancer_pools.overridden.origin_steering != null &&
      data.cloudflare_zone.this[0].filter.account.id == "lookup-account"
    )
    error_message = "Per-entry accounts, explicit empty settings, external monitors/groups, and advanced lookup account filters must remain independent."
  }
}

run "global_disable_suppresses_chain" {
  command = plan
  variables {
    create                 = false
    zone_id                = null
    load_balancer_monitors = { health = {} }
    load_balancer_pools    = { primary = { monitor = "health", origins = [{ address = "192.0.2.1" }] } }
    load_balancers         = { api = { default_pools = ["primary"], fallback_pool = "primary" } }
  }
  assert {
    condition     = length(output.load_balancers) == 0 && length(output.load_balancer_pools) == 0 && length(output.load_balancer_monitors) == 0
    error_message = "Global disable must suppress every resource without requiring zone or account IDs."
  }
}

run "reject_missing_pool_account" {
  command = plan
  variables {
    load_balancer_pools = { primary = { origins = [{ address = "192.0.2.1" }] } }
  }
  expect_failures = [cloudflare_load_balancer_pool.this]
}

run "reject_missing_monitor_account" {
  command = plan
  variables {
    load_balancer_monitors = { health = {} }
  }
  expect_failures = [cloudflare_load_balancer_monitor.this]
}

run "reject_both_balancer_name_modes" {
  command = plan
  variables {
    load_balancers = { api = { name = "api", full_name = "api.example.com", default_pools = ["id"], fallback_pool = "id" } }
  }
  expect_failures = [var.load_balancers]
}

run "reject_empty_default_pools" {
  command = plan
  variables {
    load_balancers = { api = { default_pools = [], fallback_pool = "id" } }
  }
  expect_failures = [var.load_balancers]
}

run "reject_null_fallback_pool" {
  command = plan
  variables {
    load_balancers = { api = { default_pools = ["id"], fallback_pool = null } }
  }
  expect_failures = [var.load_balancers]
}
