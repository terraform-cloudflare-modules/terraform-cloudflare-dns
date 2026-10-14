module "internal_zones" {
  source   = "../../.."
  for_each = toset(["apps", "services"])

  create_zone = true
  account_id  = var.account_id
  zone_name   = "${each.key}.internal"
  zone        = { type = "internal" }
}

module "internal_views" {
  source = "../../../modules/internal-views"

  account_id = var.account_id
  views = {
    corporate = {
      name  = "Corporate clients"
      zones = [for zone in module.internal_zones : zone.zone_id]
    }
    restricted = {
      name  = "Application clients"
      zones = [module.internal_zones["apps"].zone_id]
    }
  }
}
