module "primary_zone" {
  source = "../../.."

  create_zone = true
  account_id  = var.account_id
  zone_name   = var.primary_zone_name
  zone        = { type = "full" }
}

module "secondary_zone" {
  source = "../../.."

  create_zone = true
  account_id  = var.account_id
  zone_name   = var.secondary_zone_name
  zone        = { type = "secondary" }
}

module "transfers" {
  source = "../../../modules/zone-transfers"

  account_id = var.account_id

  tsig_keys = {
    signing = {
      name   = "transfer-key.${var.primary_zone_name}."
      algo   = "hmac-sha256"
      secret = var.transfer_secret
    }
  }

  peers = {
    primary = {
      name        = "External primary"
      ip          = "192.0.2.1"
      port        = 53
      ixfr_enable = true
      tsig_id     = "signing"
    }
    secondary = {
      name    = "External secondary"
      ip      = "192.0.2.2"
      port    = 53
      tsig_id = "signing"
    }
  }

  # Additional NOTIFY addresses, when the provider uses a separate sender.
  acls = {
    notify = { name = "External NOTIFY sender", ip_range = "192.0.2.3/32" }
  }

  incoming = {
    secondary = {
      zone_id              = module.secondary_zone.zone_id
      name                 = var.secondary_zone_name
      peers                = ["primary"]
      auto_refresh_seconds = 3600
    }
  }

  outgoing = {
    primary = {
      zone_id = module.primary_zone.zone_id
      name    = var.primary_zone_name
      peers   = ["secondary"]
    }
  }
}
