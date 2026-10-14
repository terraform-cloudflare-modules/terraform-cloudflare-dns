# ✅ Terraform Cloudflare Modules - `TODO`s

The product boundary is Cloudflare DNS. The v2 implementation manages records with optional ownership of their zone,
DNSSEC configuration, zone-wide DNS settings, and load balancing with pools and health monitors.
Standalone submodules manage account DNS settings,
and zone transfers with peers, TSIG keys, and ACLs.

## ➕ Additions

- Further internal DNS views.
- DNS Firewall.
- Load balancing monitor groups (existing group IDs are already configurable on pools).

Custom nameserver creation needs upstream provider support: the reviewed schema has
no dedicated resource. Selecting existing nameserver sets is already supported.

Add each capability with complete configurable schema coverage and explicit ownership semantics.
Defaults for new capabilities must preserve existing consumers' behavior.
Keep record map keys and resource addresses stable as capabilities are added.
Workers belongs in a separate product module, `terraform-cloudflare-workers`.
Gateway policies and resolver/client connectivity belong in a future Zero Trust module.

## ✏️ Planned Changes

Before publishing the next feature release, regenerate the reviewed Formr schema reports with engine and provider version provenance, run the
provider-backed native tests, and verify the live migration described in [UPGRADING.md](UPGRADING.md).

## 💡 Ideas

## 🔗 Links

## 🗒️ Notes
