<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Private Load Balancer

Internal (private) Azure load balancers with their backend pools, health probes, load-balancing
rules, and inbound NAT, cross-referenced by key.

[![CI](https://github.com/libre-devops/terraform-azurerm-private-lb/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-private-lb/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-private-lb?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-private-lb/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-private-lb)](./LICENSE)

---

## Overview

Internal load balancers keyed by name. Every frontend is a **private** frontend on a subnet; for
internet-facing frontends use
[`public-lb`](https://registry.terraform.io/modules/libre-devops/public-lb/azurerm/latest) instead.
The split keeps each module's defaults honest: nothing here can accidentally expose a public
endpoint.

What the module adds over the bare resources:

- **One object per load balancer**: pools, probes, rules, and NAT wired together by key, so a rule
  says `backend_pool_keys = ["app"]` and `probe_key = "http"` instead of threading resource ids.
  Raw ids are still accepted for composition with resources built elsewhere.
- **HA defaults**: frontends are zone-redundant (zones 1-3) by default on the Standard SKU, and
  `sku` is validated to Standard or Gateway, Basic is retired and rejected with a clear message.
- **HA ports**: `protocol = "All"` rules (an internal-load-balancer-only feature, the standard NVA
  pattern) are supported and validated to use port 0.
- **Gateway Load Balancer**: `sku = "Gateway"` with `tunnel_interfaces` on pools for NVA chaining.
- **A probe nudge**: a `check` block warns when a load-balancing rule ships without a health probe.

The resource group is passed by id and parsed for the name and subscription.

## Usage

```hcl
module "private_lb" {
  source  = "libre-devops/private-lb/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  lbs = {
    "lbi-ldo-uks-prd-001" = {
      frontend_ip_configurations = {
        "internal" = {
          subnet_id = module.network.subnets_ids_zipmap["snet-app-vnet-ldo-uks-prd-001"].id
        }
      }

      backend_pools = { "app" = {} }

      probes = {
        "http" = { protocol = "Http", port = 8080, request_path = "/healthz" }
      }

      rules = {
        "app-http" = {
          frontend_port     = 80
          backend_port      = 8080
          backend_pool_keys = ["app"]
          probe_key         = "http"
        }
      }
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - one zone-redundant internal load balancer with a
  backend pool, probe, and rule on a fresh vnet.
- [`examples/complete`](./examples/complete) - the full surface: static and dynamic frontends, an
  HA-ports rule, IP-based backend pool addresses, single-port and port-range NAT rules, and a NAT
  pool.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.
