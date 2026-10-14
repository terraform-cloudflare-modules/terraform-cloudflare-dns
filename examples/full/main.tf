module "dns" {
  source = "../.."

  create_zone = true
  zone_name   = var.zone_name
  account_id  = var.account_id

  zone = {
    type   = "full"
    paused = false
  }

  defaults = {
    ttl  = 1
    tags = ["managed-by:terraform"]
  }

  records = {
    www = {
      type    = "A"
      content = "192.0.2.10"
      proxied = true
    }
    www_ipv6 = {
      name    = "www"
      type    = "AAAA"
      content = "2001:db8::10"
      proxied = true
    }
    mail_primary = {
      name     = "@"
      type     = "MX"
      content  = "mail.example.net"
      priority = 10
      ttl      = 3600
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
