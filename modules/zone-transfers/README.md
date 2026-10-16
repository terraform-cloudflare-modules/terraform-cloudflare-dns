# Cloudflare DNS zone transfers

Manage incoming and outgoing transfers with reusable account-level peers, TSIG
keys, and ACLs. This standalone submodule supports multiple zones and exposes every
configurable field of the five upstream transfer resources. It does not create
zones or DNS records. Cloudflare zone transfers require Enterprise access.

## Usage

```hcl
variable "cloudflare_account_id" {
  description = "Account with zone transfer access."
  type        = string
}

variable "transfer_secret" {
  description = "Base64-encoded TSIG secret shared with the external primary."
  type        = string
  sensitive   = true
}

variable "secondary_zone_id" {
  description = "Existing secondary zone ID."
  type        = string
}

module "transfers" {
  source = "terraform-cloudflare-modules/dns/cloudflare//modules/zone-transfers"

  account_id = var.cloudflare_account_id

  tsig_keys = {
    signing = {
      name   = "transfer-key.example.com."
      algo   = "hmac-sha256"
      secret = var.transfer_secret
    }
  }

  peers = {
    primary = {
      name        = "External primary"
      ip          = "192.0.2.1"
      port        = 53
      ixfr_enable = true
      tsig_id     = "signing"
    }
  }

  incoming = {
    secondary = {
      zone_id              = var.secondary_zone_id
      name                 = "example.com"
      peers                = ["primary"]
      auto_refresh_seconds = 3600
    }
  }
}
```

## Examples

See the [full example](../../examples/modules/zone-transfers) for all inputs,
composition with related resources, and prerequisites.

See the
[complete example](../../examples/modules/zone-transfers/main.tf) for zone creation and
both transfer directions. Use a secondary zone for incoming transfers and match
the external primary's signing and transfer configuration. The root module's
`zone`, `dnssec`, and `dns_settings` inputs handle those zone-specific settings.

## Ownership and references

Every map defaults to empty. An entry opts into managing one resource, and
`create = false` suppresses the entire submodule. Use stable map keys: changing a
key changes its Terraform address unless accompanied by a `moved` block.
Zone, peer, and TSIG IDs may be unknown until apply; map keys must be known at plan time.
Only one entry per direction may manage a given zone ID.

| Input | Scope and behavior |
| --- | --- |
| `acls` | Account-wide allow rules with `ip_range`; configure only additional ranges required for transfer traffic. |
| `tsig_keys` | Account-level signing keys. Explicit `name` is preserved; omitted names use map keys. `algo` is trimmed/lowercased, and `secret` is unchanged. |
| `peers` | Account-level servers. `tsig_id` accepts a managed TSIG key or an existing ID. Null optional properties defer to the provider. |
| `incoming` | One transfer configuration per zone; `peers` accepts managed peer keys or existing IDs. |
| `outgoing` | One transfer configuration per zone; the same peer reference convention applies. |

Account resources inherit `account_id`, with a per-entry override available.
Incoming and outgoing entries require their own zone ID and name; names are
trimmed, lowercased, and stripped of a trailing dot. Other names are passed through.
Transfer peer collections are sets, so ordering has no significance. Explicit
empty sets, zero values, and false flags pass through for provider validation.
Omitted incoming refresh intervals defer to the provider's default.

A matching managed key takes precedence over an external ID. Unmatched references
are forwarded unchanged; a misspelled key will be rejected by the API. Avoid map
keys that collide with external IDs. Peers and TSIG keys can be shared across
zones: designate one owning module instance and pass output IDs elsewhere.
Transfers with only external peer IDs do not require `account_id`.
The module does not verify account membership of external zone, peer, or key IDs.

Dependencies order TSIG keys before peers and peers before transfers. Transfers
also wait for ACLs managed by this invocation. Cloudflare's ACLs apply to the
entire account, and the external provider must separately permit Cloudflare's
transfer traffic. See [zone transfers][transfers] and [ACL configuration][acls].

## TSIG secrets

Supply already-encoded TSIG secret material through `tsig_keys[*].secret`.
The entire input and `tsig_keys` output are marked sensitive. Only map keys are
declassified for resource addresses: never use a secret as a map key.
The `tsig_key_ids` output exposes IDs without exposing secrets.
Sensitive marking hides normal CLI output; Terraform state still contains the
secret. Use an appropriately protected state backend and credential source.

## Adoption and removal

Existing resources in the same state can move into this submodule without changing IDs:

```hcl
moved {
  from = cloudflare_dns_zone_transfers_peer.primary
  to   = module.transfers.cloudflare_dns_zone_transfers_peer.this["primary"]
}
```

Use equivalent moves for ACLs, TSIG keys, and incoming/outgoing configurations.
Match existing properties and review the plan before applying. Remote resources
not already in state need the import procedure for the installed provider version;
transfer configurations use zone IDs, while account resources use compound IDs.

Removing a map entry or setting `create = false` plans destruction. To retain a
shared remote resource while handing off ownership, coordinate a state move or
removal before removing its configuration. Confirm dependent zones and external
DNS providers are ready before deleting keys, peers, or transfer configuration.

## Verification

The [schema report](docs/SCHEMA.md) covers every configurable field. Generate and
check it from the repository root with:

```sh
formr schema modules/zone-transfers --schema-file secrets/schema.json \
  -o modules/zone-transfers/docs/SCHEMA.md
formr check modules/zone-transfers --schema-file secrets/schema.json \
  --report modules/zone-transfers/docs/SCHEMA.md
```

The supplied raw schema snapshot does not include engine/provider version
provenance. Refresh it with provenance before publication. Mock tests exercise
references, account overrides, complete outputs, disabling, and unknown values.
They do not verify actual transfers or API restrictions; verify AXFR/IXFR, NOTIFY,
TSIG authentication, SOA progression, and a second no-change plan with test zones.

[transfers]: https://developers.cloudflare.com/dns/zone-setups/zone-transfers/
[acls]: https://developers.cloudflare.com/dns/zone-setups/zone-transfers/access-control-lists/

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.8 |
| cloudflare | >= 5.28.0, < 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| cloudflare | >= 5.28.0, < 6.0.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_dns_zone_transfers_acl.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_zone_transfers_acl) | resource |
| [cloudflare_dns_zone_transfers_incoming.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_zone_transfers_incoming) | resource |
| [cloudflare_dns_zone_transfers_outgoing.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_zone_transfers_outgoing) | resource |
| [cloudflare_dns_zone_transfers_peer.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_zone_transfers_peer) | resource |
| [cloudflare_dns_zone_transfers_tsig.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_zone_transfers_tsig) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_id | Default account for ACLs, TSIG keys, and peers. Individual entries can override it. Not required when only configuring transfers with existing peer IDs. | `string` | `null` | no |
| acls | Account-wide transfer ACLs keyed by stable identifiers. Name defaults to the key; ip\_range passes through unchanged. | ```map(object({ account_id = optional(string) name = optional(string) ip_range = string }))``` | `{}` | no |
| create | Whether to manage any transfer resources. Map keys must be known at plan time; resource IDs and secrets may be unknown. | `bool` | `true` | no |
| incoming | Incoming transfers keyed by stable identifiers. Supply zone\_id and the zone's name, normalized as a DNS name. peers accepts managed peer keys or existing IDs. Zones must already exist or be supplied by another resource/module. | ```map(object({ zone_id = string name = string peers = set(string) auto_refresh_seconds = optional(number) }))``` | `{}` | no |
| outgoing | Outgoing transfers keyed by stable identifiers. Supply zone\_id and the zone's name, normalized as a DNS name. peers accepts managed peer keys or existing IDs. Resource keys are independent of zone and peer IDs. | ```map(object({ zone_id = string name = string peers = set(string) }))``` | `{}` | no |
| peers | Account-level transfer peers keyed by stable identifiers. Name defaults to the key; tsig\_id accepts a managed TSIG key or an existing ID. Null properties defer to the provider; explicit false and zero pass through. | ```map(object({ account_id = optional(string) name = optional(string) ip = optional(string) port = optional(number) ixfr_enable = optional(bool) tsig_id = optional(string) }))``` | `{}` | no |
| tsig\_keys | TSIG keys keyed by stable, non-secret identifiers. Name defaults to the key; algo is trimmed/lowercased; secret is preserved exactly. Keys are exposed in resource addresses; all values and the complete output are sensitive. | ```map(object({ account_id = optional(string) name = optional(string) algo = string secret = string }))``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| acls | Complete managed transfer ACLs keyed by input keys. Empty when disabled. |
| incoming | Complete incoming transfers keyed by input keys, including resolved peer IDs, SOA serials, and timestamps. Empty when disabled. |
| outgoing | Complete outgoing transfers keyed by input keys, including resolved peer IDs, SOA serials, and timestamps. Empty when disabled. |
| peers | Complete managed peers keyed by input keys, including resolved TSIG IDs. Empty when disabled. |
| tsig\_key\_ids | Managed TSIG IDs keyed by input keys, without secret material. |
| tsig\_keys | Complete managed TSIG resources, including secrets, keyed by input keys. Sensitive; empty when disabled. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](../../docs/CONTRIBUTING.md) for contribution guidelines and
[UPGRADING.md](../../docs/UPGRADING.md) for adoption and migration guidance.
The generated [schema report](docs/SCHEMA.md) documents provider coverage.

## Authors

Maintained by [Terraform Cloudflare Modules](https://github.com/terraform-cloudflare-modules).
See [AUTHORS](../../.github/AUTHORS) and [CODEOWNERS](../../.github/CODEOWNERS).

## License

MIT. See [LICENSE](../../LICENSE).
