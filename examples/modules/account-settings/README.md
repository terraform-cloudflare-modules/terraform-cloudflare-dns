# Account DNS settings

Every account-settings input and nested setting is shown. Supply the account and
zone name; this example owns account-wide defaults and creates a zone afterward.
Choose one settings owner per account. Existing zones do not inherit new defaults.

Optional null fields defer to Cloudflare. Internal fallback requires an internal
zone reference; supply it only for an appropriate internal-zone setup. Foundation
DNS is deprecated; select the nameserver type instead. Custom SOA values and other
advanced options require the corresponding account entitlements.

See [main.tf](main.tf) for the configuration and [variables.tf](variables.tf) for required inputs.
