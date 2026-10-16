# Internal DNS views

Every internal-view input is shown. Supply an account with internal DNS access.
The example creates two internal zones and shares their IDs between two views.
Each view owns its complete membership set. Per-view account overrides must match
the account of the member zones. Resolver selection, client access, and Gateway
policies belong to your separate Zero Trust configuration.

See [main.tf](main.tf) for the configuration and [variables.tf](variables.tf) for required inputs.
