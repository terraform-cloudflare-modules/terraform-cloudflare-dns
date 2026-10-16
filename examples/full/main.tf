module "dns" {
  source = "../.."

  create      = true
  zone_id     = null # Alternative: existing zone ID with create_zone = false.
  zone_filter = null # Alternative: advanced lookup; see lookup_only below.
  create_zone = true
  zone_name   = var.zone_name
  account_id  = var.account_id

  zone = {
    type                = "full"
    paused              = false
    vanity_name_servers = [] # Supply delegated vanity nameservers when entitled.
  }

  create_dns_settings = true
  dns_settings = {
    foundation_dns      = null                         # Deprecated: use nameservers.type instead.
    internal_dns        = { reference_zone_id = null } # Only for internal zone fallback.
    flatten_all_cnames  = false
    multi_provider      = true
    ns_ttl              = 86400
    secondary_overrides = false
    zone_mode           = "standard"
    nameservers = {
      type              = "cloudflare.standard"
      ns_set            = null # Numeric set for eligible advanced nameservers.
      nameserver_set_id = null # Existing custom set ID; alternative to ns_set.
    }
    soa = {
      expire  = 604800
      mname   = null # Cloudflare chooses the primary; custom SOA requires entitlement.
      refresh = 10000
      retry   = 2400
      min_ttl = 1800
      rname   = "admin.example.com"
      ttl     = 3600
    }
  }

  create_dnssec = true
  dnssec = {
    status              = "active"
    dnssec_multi_signer = true
    dnssec_presigned    = false
    dnssec_use_nsec3    = false
  }

  defaults = {
    ttl                     = 1
    proxied                 = false
    comment                 = "Managed DNS"
    include_shadow_metadata = false
    private_routing         = false
    settings = {
      flatten_cname = false
      ipv4_only     = false
      ipv6_only     = false
    }
    tags = ["managed-by:terraform"]
  }

  load_balancer_monitors = {
    https = {
      account_id       = var.account_id
      allow_insecure   = false
      consecutive_down = 2
      consecutive_up   = 2
      description      = "HTTPS readiness"
      expected_body    = "healthy"
      follow_redirects = true
      interval         = 60
      port             = 443
      probe_zone       = var.zone_name
      retries          = 2
      timeout          = 5
      type             = "https"
      method           = "GET"
      path             = "/health"
      expected_codes   = "2xx"
      header           = { Host = ["api.${var.zone_name}"] }
    }
  }

  load_balancer_pools = {
    europe = {
      account_id         = var.account_id
      description        = "European origins"
      enabled            = true
      health_sources     = ["regional", "global"]
      latitude           = 50.11
      longitude          = 8.68
      minimum_origins    = 1
      monitor_group      = null # Alternative to monitor: existing/shared group ID.
      notification_email = var.notification_email
      load_shedding = {
        default_percent = 0
        default_policy  = "random"
        session_percent = 0
        session_policy  = "hash"
      }
      notification_filter = {
        origin = { disable = false, healthy = true }
        pool   = { disable = false, healthy = true }
      }
      origin_steering = { policy = "random" }
      name            = "dns-example-europe"
      monitor         = "https"
      check_regions   = ["WEU"]
      origins = [{
        name               = "europe"
        address            = var.europe_origin
        enabled            = true
        flatten_cname      = true
        header             = { host = ["api.${var.zone_name}"] }
        port               = 443
        virtual_network_id = null # Supply a private network ID for private origins.
        weight             = 1
      }]
    }
    america = {
      name          = "dns-example-america"
      monitor       = "https"
      check_regions = ["ENAM"]
      origins       = [{ name = "america", address = var.america_origin }]
    }
  }

  load_balancers = {
    api = {
      name              = "api"
      full_name         = null # Alternative to name: an exact FQDN.
      description       = "Geographic HTTPS balancing"
      enabled           = true
      networks          = ["standard"]
      adaptive_routing  = { failover_across_pools = true }
      location_strategy = { mode = "resolver_ip", prefer_ecs = "proximity" }
      pop_pools         = { FRA = ["europe"] }
      # Weights apply with steering_policy = "random" rather than "geo".
      random_steering      = { default_weight = 1, pool_weights = { europe = 2, america = 1 } }
      session_affinity     = "cookie"
      session_affinity_ttl = 1800
      session_affinity_attributes = {
        drain_duration         = 60
        headers                = [] # Used by header affinity rather than cookie affinity.
        require_all_headers    = false
        samesite               = "Auto"
        secure                 = "Auto"
        zero_downtime_failover = "sticky"
      }
      rules = [
        {
          name       = "maintenance"
          condition  = "http.request.uri.path eq \"/maintenance\""
          disabled   = true
          priority   = 1
          terminates = true
          fixed_response = {
            content_type = "text/plain"
            location     = null # For redirect responses, supply the destination URL instead.
            message_body = "Maintenance"
            status_code  = 503
          }
        },
        {
          name       = "regional-override"
          condition  = "ip.src.country eq \"DE\""
          disabled   = true
          priority   = 2
          terminates = true
          overrides = {
            adaptive_routing  = { failover_across_pools = true }
            country_pools     = { DE = ["europe"] }
            default_pools     = ["europe", "america"]
            fallback_pool     = "america"
            location_strategy = { mode = "resolver_ip", prefer_ecs = "proximity" }
            pop_pools         = { FRA = ["europe"] }
            random_steering   = { default_weight = 1, pool_weights = { europe = 2 } }
            region_pools      = { ENAM = ["america"] }
            session_affinity  = "cookie"
            session_affinity_attributes = {
              drain_duration         = 60
              headers                = []
              require_all_headers    = false
              samesite               = "Auto"
              secure                 = "Auto"
              zero_downtime_failover = "sticky"
            }
            session_affinity_ttl = 1800
            steering_policy      = "geo"
            ttl                  = 60
          }
        }
      ]
      default_pools   = ["europe", "america"]
      fallback_pool   = "america"
      steering_policy = "geo"
      country_pools   = { DE = ["europe", "america"] }
      region_pools    = { ENAM = ["america", "europe"] }
      proxied         = true # Rules and HTTP affinity require proxying.
      ttl             = 60
    }
  }

  records = {
    www = {
      name                    = "www"
      full_name               = null # Mutually exclusive with name.
      comment                 = "Public website"
      include_shadow_metadata = false
      private_routing         = false
      priority                = null # Used by MX; see mail below.
      ttl                     = 1
      tags                    = ["service:web"]
      settings                = { flatten_cname = false, ipv4_only = false, ipv6_only = false }
      type                    = "A"
      content                 = "192.0.2.10"
      proxied                 = true
    }
    www_ipv6 = {
      name    = "www"
      type    = "AAAA"
      content = "2001:db8::10"
      proxied = true
    }
    mail = {
      name     = "@"
      type     = "MX"
      priority = 20 # Bare list hostnames inherit this; inline priorities override it.
      content = [
        "aspmx.l.google.com",
        "5 alt1.aspmx.l.google.com",
        "5 alt2.aspmx.l.google.com",
        "10 alt3.aspmx.l.google.com",
        "10 alt4.aspmx.l.google.com",
      ]
      ttl = 3600
    }
    verification = {
      name    = "_verification"
      type    = "TXT"
      content = "Preserve This Exact Value"
      comment = "Domain verification"
      tags    = []
    }
    certificate_authority = {
      name = "@"
      type = "CAA"
      data = {
        flags = 0
        tag   = "issue"
        value = "letsencrypt.org"
      }
    }
    location = {
      name = "location"
      type = "LOC"
      data = {
        altitude       = 100
        lat_degrees    = 50
        lat_direction  = "N"
        lat_minutes    = 6
        lat_seconds    = 36
        long_degrees   = 8
        long_direction = "E"
        long_minutes   = 40
        long_seconds   = 48
        precision_horz = 10
        precision_vert = 10
        size           = 1
      }
    }
    naptr = {
      name = "sip"
      type = "NAPTR"
      data = {
        order       = 10
        preference  = 20
        flags       = "S"
        service     = "SIP+D2U"
        regex       = ""
        replacement = "_sip._udp.${var.zone_name}"
      }
    }
    ssh = {
      name = "ssh"
      type = "SSHFP"
      data = { algorithm = 4, type = 2, fingerprint = var.ssh_fingerprint }
    }
    tls = {
      name = "_443._tcp.www"
      type = "TLSA"
      data = { usage = 3, selector = 1, matching_type = 1, certificate = var.tlsa_certificate }
    }
    delegation = {
      name = "child"
      type = "DS"
      data = { algorithm = 13, digest_type = 2, key_tag = var.child_key_tag, digest = var.child_ds_digest }
    }
    external_key = {
      name = "@"
      type = "DNSKEY"
      # Publish external keys only after enabling multi-signer mode and coordinating delegation.
      content = null
      data    = { flags = 257, protocol = 3, algorithm = 13, public_key = var.external_dnskey }
    }
    sip = {
      name = "_sip._tcp"
      type = "SRV"
      data = {
        priority = 10
        weight   = 20
        port     = 5060
        target   = "sip.example.net"
      }
    }
  }
}

# Lookup-only alternatives own no records and do not adopt the managed zone above.
module "lookup_only" {
  source     = "../.."
  depends_on = [module.dns]
  zone_filter = {
    account   = { id = var.account_id, name = null } # Name may filter instead of ID.
    direction = "asc"
    match     = "all"
    name      = var.zone_name
    order     = "name"
    status    = null # "active" only once delegation is complete.
    type      = ["full"]
  }
}

module "direct_id" {
  source  = "../.."
  zone_id = module.dns.zone_id
}
