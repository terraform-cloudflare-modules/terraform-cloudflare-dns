# Cloudflare DNS Firewall

Manage account-level `cloudflare_dns_firewall` clusters independently of zone
management. Each `clusters` entry opts into owning one cluster. An empty map or
`create = false` creates no resources.

```hcl
module "dns_firewall" {
  source = "terraform-cloudflare-modules/dns/cloudflare//modules/dns-firewall"

  account_id = var.account_id
  clusters = {
    authoritative = {
      name                   = "External authoritative DNS"
      upstream_ips           = ["192.0.2.1", "192.0.2.2"]
      dns_firewall_ip_count  = 2
      minimum_cache_ttl      = 0
      maximum_cache_ttl      = 3600
      negative_cache_ttl     = 60
      deprecate_any_requests = true
      attack_mitigation = {
        enabled                      = true
        only_when_upstream_unhealthy = true
      }
    }
  }
}
```

## Cluster behavior

DNS Firewall fronts external authoritative nameservers, caching responses and
protecting their upstream infrastructure. It is an Enterprise paid add-on.
See the [Cloudflare product documentation][firewall] and the
[complete example](../../examples/modules/dns-firewall/main.tf). Replace documentation IPs
with your upstream server addresses before applying.

`upstream_ips` is a required set. Names default to map keys; explicit names and
addresses retain their original values. Individual `account_id` values override
the module default. The module exposes every configurable resource field,
including both attack-mitigation flags, ANY-query handling, ECS fallback,
cache TTL bounds, negative caching, rate limiting, retries, and address count.

`dns_firewall_ip_count` is a creation-time setting according to the provider
schema; choose it before creating the cluster. Do not assume changing it later
will resize an existing cluster. Null optional fields defer to the provider;
explicit false, zero, empty sets, and empty nested objects pass through for
upstream validation. Cache settings and client-facing answer TTLs have different
semantics; consult the installed provider's field descriptions when configuring them.

The `clusters` output preserves complete resources, including assigned
`dns_firewall_ips`, IDs, and modification timestamps. Delegation and external
nameserver configuration are separate tasks; this submodule does not change
registrar settings or create DNS zones. Assign each cluster a single owner and
reuse its output addresses where needed.

Deleting a map entry destroys its cluster. Coordinate delegation and dependent
infrastructure before removing an in-use cluster or handing off its ownership.

[firewall]: https://developers.cloudflare.com/dns/dns-firewall/

## Adoption and verification

These submodules were added after v2.0.0. Use a local checkout containing them until
a release includes them, then pin that release when using the Registry source.
Provider configuration and credentials belong to the caller.

When an existing resource is already managed in the same state, retain its ID with
a caller-root move and remove the old declaration:

```hcl
moved {
  from = cloudflare_dns_firewall.existing
  to   = module.dns_firewall.cloudflare_dns_firewall.this["authoritative"]
}
```

Match existing settings and inspect the plan before applying. For resources not
already in state, follow the import procedure for the installed provider version.
For a handoff between states, coordinate ownership before applying either state.
Setting `create = false` plans resource removal; it is not a state-only handoff.

The [schema report](docs/SCHEMA.md) includes every configurable resource field.
From the repository root, regenerate and check it with:

```sh
formr schema modules/dns-firewall --schema-file secrets/schema.json \
  -o modules/dns-firewall/docs/SCHEMA.md
formr check modules/dns-firewall --schema-file secrets/schema.json \
  --report modules/dns-firewall/docs/SCHEMA.md
```

The supplied raw snapshot lacks engine/provider version provenance; refresh it
with provenance before publication. Native mock tests cover configuration,
outputs, disabling, account checks, and unknown inputs. They do not verify live
API behavior or account entitlements. Exercise creation, updates, a second
no-change plan, and removal in a dedicated test account before production use.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 5.28.0, < 6.0.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Default account for managed entries. Individual entries can override it. | `string` | `null` | no |
| <a name="input_clusters"></a> [clusters](#input\_clusters) | DNS Firewall clusters keyed by stable identifiers. Names default to keys; all upstream settings, including nested attack mitigation, are configurable. Null optional fields defer to the provider; explicit false, zero, and empty collections/objects pass through. | ```map(object({ account_id = optional(string) attack_mitigation = optional(object({ enabled = optional(bool) only_when_upstream_unhealthy = optional(bool) })) deprecate_any_requests = optional(bool) dns_firewall_ip_count = optional(number) ecs_fallback = optional(bool) maximum_cache_ttl = optional(number) minimum_cache_ttl = optional(number) name = optional(string) negative_cache_ttl = optional(number) ratelimit = optional(number) retries = optional(number) upstream_ips = set(string) }))``` | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to manage resources in this submodule. Must be known at plan time. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_clusters"></a> [clusters](#output\_clusters) | Complete managed clusters keyed by input keys, including computed properties. Empty when disabled or unconfigured. |
<!-- END_TF_DOCS -->
