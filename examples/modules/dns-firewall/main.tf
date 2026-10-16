module "dns_firewall" {
  source = "../../../modules/dns-firewall"

  create = true

  account_id = var.account_id
  clusters = {
    authoritative = {
      account_id             = var.account_id # Overrides the module default.
      ratelimit              = 1000
      name                   = "External authoritative DNS"
      upstream_ips           = ["192.0.2.1", "192.0.2.2"]
      dns_firewall_ip_count  = 2
      deprecate_any_requests = true
      ecs_fallback           = false
      minimum_cache_ttl      = 30
      maximum_cache_ttl      = 3600
      negative_cache_ttl     = 60
      retries                = 2
      attack_mitigation = {
        enabled                      = true
        only_when_upstream_unhealthy = true
      }
    }
  }
}
