resource "cloudflare_load_balancer_monitor" "api" {
  account_id     = var.account_id
  type           = "https"
  method         = "GET"
  path           = "/health"
  expected_codes = "2xx"
  header         = { Host = [var.hostname] }
}

module "monitor_groups" {
  source = "../../../modules/monitor-groups"

  create = true

  account_id = var.account_id
  groups = {
    service = {
      account_id  = var.account_id # Overrides the module default.
      description = "Shared API health checks"
      members = [{
        monitor_id      = cloudflare_load_balancer_monitor.api.id
        enabled         = true
        monitoring_only = false
        must_be_healthy = true
      }]
    }
  }
}

module "dns" {
  source = "../../.."

  account_id = var.account_id
  zone_id    = var.zone_id
  load_balancer_pools = {
    primary = {
      monitor_group = module.monitor_groups.groups.service.id
      origins       = [{ name = "primary", address = "192.0.2.1" }]
    }
  }
  load_balancers = {
    service = {
      full_name     = var.hostname
      default_pools = ["primary"]
      fallback_pool = "primary"
      ttl           = 60
    }
  }
}
