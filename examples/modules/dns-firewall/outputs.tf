output "clusters" {
  description = "Complete firewall clusters, including assigned dns_firewall_ips."
  value       = module.dns_firewall.clusters
}
