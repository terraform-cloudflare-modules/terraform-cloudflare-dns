# Shared health monitor groups

Every monitor-group input is shown. Supply an account with monitor-group access,
an existing zone ID, and a hostname. Replace the origin IP with a reachable HTTPS
server that answers `/health`. The example creates a monitor and group, then passes
the group ID into a load-balancing pool. Pools and groups can be shared across zones;
keep one owner for each shared resource. Member flags are explicit; use
`monitoring_only` for observation without contributing to health quorum.

See [main.tf](main.tf) for the configuration and [variables.tf](variables.tf) for required inputs.
