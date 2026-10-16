# Complete DNS configuration

This example lists every root input and nested field. It creates a zone, DNSSEC, DNS
settings, record types, health monitors, pools, and a proxied geographic load balancer.
Supply all declared variables with real domain, origin, notification, and key material.
The documentation addresses in the records must also be replaced before use.

You need Load Balancing and the relevant advanced DNS, SOA, and rules entitlements.
The HTTPS origins must return `healthy` on `/health`. The external DNSKEY requires a
coordinated multi-signer deployment; use the external signer's actual public key and
publish the correct DS through your registrar. The child DS and TLSA/SSHFP records
must match their real keys. Import an existing zone before adopting it.

Null entries show optional alternatives without inventing resource IDs. Custom
nameserver sets, internal DNS fallback IDs, monitor groups, and private networks
must exist before supplying those values. Internal fallback requires an internal
zone; it cannot be enabled on this full public zone. Use `ns_set` or a custom
`nameserver_set_id` only with its corresponding nameserver type and entitlement.

The balancer demonstrates geo steering and cookie affinity. Random weights are
only effective with random steering; header affinity fields apply when selecting
header affinity. The rules start disabled. A fixed response and routing overrides
are shown in separate rules; a redirect uses `location` instead of a body response.
Use DNS-only balancing if HTTP rules and affinity are unnecessary.

The lookup and direct-ID module calls illustrate alternative selection methods;
they own no records. Normally choose one selector per module call. `name` and
`full_name`, and record `content` and `data`, are mutually exclusive alternatives.
Set `create = false` only when intentionally planning removal of managed resources.

Review [ownership and adoption](../../docs/UPGRADING.md) before applying. This is
an interface reference requiring account-specific choices, not a minimal setup.

See [main.tf](main.tf) for the configuration and [variables.tf](variables.tf) for required inputs.
