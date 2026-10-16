# DNS Firewall clusters

Every DNS Firewall input is shown, including an explicit per-cluster account
override. Supply an account with DNS Firewall access and replace the documentation
IP addresses with reachable authoritative servers. Configure delegation to the
assigned firewall addresses separately. Cache TTLs and rate limits affect traffic
for all domains served through the cluster; choose values appropriate to your servers.

See [main.tf](main.tf) for the configuration and [variables.tf](variables.tf) for required inputs.
