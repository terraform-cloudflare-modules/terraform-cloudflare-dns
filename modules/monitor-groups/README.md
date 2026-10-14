# Cloudflare load balancing monitor groups

Manage reusable `cloudflare_load_balancer_monitor_group` resources independently
of zones, pools, and monitors. Each `groups` entry opts into owning one group.
An empty map or `create = false` creates no resources.

```hcl
module "monitor_groups" {
  source = "terraform-cloudflare-modules/dns/cloudflare//modules/monitor-groups"

  account_id = var.account_id
  groups = {
    service = {
      description = "API health checks"
      members = [{
        monitor_id      = var.api_monitor_id
        enabled         = true
        monitoring_only = false
        must_be_healthy = true
      }]
    }
  }
}
```

## Membership and reuse

Each group requires `description` and a set of `members`. Every member exposes all
four required upstream inputs: `monitor_id`, `enabled`, `monitoring_only`, and
`must_be_healthy`. Flags have no module-defined defaults. Sets are unordered;
resource identities depend on group keys, not member IDs or positions.

Monitor IDs can come from existing infrastructure, resource attributes, or module
outputs. This submodule does not create monitors or pools. Use the resulting group
ID in a root DNS module's `load_balancer_pools[*].monitor_group`. The
[complete example](../../examples/modules/monitor-groups/main.tf) composes a monitor,
a shared group, and a pool using that group.

The `groups` output returns complete resources, including IDs, timestamps, and
computed member metadata. Per-entry `account_id` overrides the module default.
Use resources from the appropriate account; this module does not look up the
account membership of referenced monitor IDs.

Monitor groups require the corresponding Enterprise Load Balancing entitlement.
Enabled members participate according to their health flags; observation-only
members do not contribute to health quorum. See [Cloudflare's monitor group
behavior][groups] for the interaction between critical monitors and quorum.
Descriptions, booleans, and explicit empty membership are forwarded unchanged for
provider validation. No additional restrictions are inferred from the schema.

A group can be used by multiple pools. Designate one owner and pass its output ID
to consumers rather than declaring the same group in each zone's configuration.
Before deleting a group, update consuming pools; removing a member updates group
membership, while removing the map entry destroys the group.

[groups]: https://developers.cloudflare.com/load-balancing/monitors/monitor-groups/

## Adoption and verification

These submodules were added after v2.0.0. Use a local checkout containing them until
a release includes them, then pin that release when using the Registry source.
Provider configuration and credentials belong to the caller.

When an existing resource is already managed in the same state, retain its ID with
a caller-root move and remove the old declaration:

```hcl
moved {
  from = cloudflare_load_balancer_monitor_group.existing
  to   = module.monitor_groups.cloudflare_load_balancer_monitor_group.this["service"]
}
```

Match existing settings and inspect the plan before applying. For resources not
already in state, follow the import procedure for the installed provider version.
For a handoff between states, coordinate ownership before applying either state.
Setting `create = false` plans resource removal; it is not a state-only handoff.

The [schema report](docs/SCHEMA.md) includes every configurable resource field.
From the repository root, regenerate and check it with:

```sh
formr schema modules/monitor-groups --schema-file secrets/schema.json \
  -o modules/monitor-groups/docs/SCHEMA.md
formr check modules/monitor-groups --schema-file secrets/schema.json \
  --report modules/monitor-groups/docs/SCHEMA.md
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
| <a name="input_create"></a> [create](#input\_create) | Whether to manage resources in this submodule. Must be known at plan time. | `bool` | `true` | no |
| <a name="input_groups"></a> [groups](#input\_groups) | Reusable monitor groups keyed by stable identifiers. Each member supplies a monitor ID and all required health flags. Members are unordered; false flags, empty descriptions, and empty member sets pass through for provider validation. | ```map(object({ account_id = optional(string) description = string members = set(object({ enabled = bool monitor_id = string monitoring_only = bool must_be_healthy = bool })) }))``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_groups"></a> [groups](#output\_groups) | Complete managed groups keyed by input keys, including computed properties. Empty when disabled or unconfigured. |
<!-- END_TF_DOCS -->
