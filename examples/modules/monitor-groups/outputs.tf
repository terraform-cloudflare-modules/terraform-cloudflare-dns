output "groups" {
  description = "Shared monitor group IDs, members, and metadata."
  value       = module.monitor_groups.groups
}

output "load_balancers" {
  description = "Load balancers using the shared monitor group through their pool."
  value       = module.dns.load_balancers
}
