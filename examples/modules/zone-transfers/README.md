# DNS zone transfers

Every zone-transfers input is shown, including per-entry account overrides.
Supply an Enterprise account with zone transfers enabled, two domain names, and
a base64-encoded TSIG secret agreed with the external DNS operator. Replace the
peer and NOTIFY documentation IPs with real addresses.

The example creates a primary zone for outgoing transfers and a secondary zone for
incoming transfers. Configure matching TSIG, ACLs, NOTIFY, and transfer permissions
at the external servers. Peer references use managed map keys; existing peer or
TSIG IDs can be supplied instead. Refresh intervals must be at least 300 seconds.
The secret is sensitive but remains in Terraform state. Import pre-existing zones
and transfer resources before taking ownership.

See [main.tf](main.tf) for the configuration and [variables.tf](variables.tf) for required inputs.
