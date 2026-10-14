output "groups" {
  description = "Complete managed groups keyed by input keys, including computed properties. Empty when disabled or unconfigured."
  value       = cloudflare_load_balancer_monitor_group.this
}
