module "dns" {
  source  = "../.."
  zone_id = var.zone_id

  records = {
    web  = { name = "www", type = "A", content = ["192.0.2.10", "192.0.2.11"] }
    apex = { name = "@", type = "TXT", content = "example-verification" }
  }
}
