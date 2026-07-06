locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  vnet_name = "vnet-${var.short}-${var.loc}-${terraform.workspace}-002"
  lb_name   = "lbi-${var.short}-${var.loc}-${terraform.workspace}-002"
  snet_app  = "snet-app-${local.vnet_name}"
  snet_nva  = "snet-nva-${local.vnet_name}"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-private-lb" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

module "network" {
  source  = "libre-devops/network/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  vnet_name     = local.vnet_name
  address_space = ["10.0.0.0/16"]
  subnets = {
    (local.snet_app) = { address_prefixes = ["10.0.1.0/24"] }
    (local.snet_nva) = { address_prefixes = ["10.0.2.0/24"] }
  }
}

# Complete call: every feature of the module on one internal load balancer.
#
# - Two frontends: "app" takes the zone-redundant default; "nva" pins a static address and a
#   single zone (rules must then name their frontend, there is more than one).
# - Two backend pools: "app" is a plain NIC-attached pool; "nva" is vnet-associated so it can
#   carry IP-based backend addresses directly.
# - Probes: a Tcp probe and an Http probe with a request path and tuned thresholds.
# - Rules: a standard Tcp rule with load distribution and idle timeout, plus an HA-ports rule
#   (protocol All, ports 0, an internal-only feature) on the dedicated "nva" frontend.
# - NAT: a single-port NAT rule, a port-range NAT rule fanning out over the "app" pool, and a
#   legacy NAT pool for VMSS-style setups.
module "private_lb" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  lbs = {
    (local.lb_name) = {
      frontend_ip_configurations = {
        "app" = {
          subnet_id = module.network.subnet_ids[local.snet_app]
        }
        "nva" = {
          subnet_id          = module.network.subnet_ids[local.snet_nva]
          private_ip_address = "10.0.2.10"
          zones              = ["1"]
        }
      }

      backend_pools = {
        "app" = {}
        "nva" = {
          virtual_network_id = module.network.vnet_id
          addresses = {
            "nva-a" = { virtual_network_id = module.network.vnet_id, ip_address = "10.0.2.20" }
            "nva-b" = { virtual_network_id = module.network.vnet_id, ip_address = "10.0.2.21" }
          }
        }
      }

      probes = {
        "tcp-8080" = { port = 8080 }
        "http-health" = {
          protocol            = "Http"
          port                = 8080
          request_path        = "/healthz"
          interval_in_seconds = 15
          probe_threshold     = 2
        }
      }

      rules = {
        "app-http" = {
          frontend_ip_configuration_name = "app"
          frontend_port                  = 80
          backend_port                   = 8080
          backend_pool_keys              = ["app"]
          probe_key                      = "http-health"
          load_distribution              = "SourceIP"
          idle_timeout_in_minutes        = 15
          tcp_reset_enabled              = true
        }
        "nva-ha-ports" = {
          frontend_ip_configuration_name = "nva"
          protocol                       = "All"
          frontend_port                  = 0
          backend_port                   = 0
          backend_pool_keys              = ["nva"]
          probe_key                      = "tcp-8080"
          floating_ip_enabled            = true
        }
      }

      nat_rules = {
        "rule-ssh-admin" = {
          frontend_ip_configuration_name = "app"
          frontend_port                  = 2222
          backend_port                   = 22
        }
        "rule-ssh-fleet" = {
          frontend_ip_configuration_name = "app"
          frontend_port_start            = 50000
          frontend_port_end              = 50019
          backend_port                   = 22
          backend_pool_key               = "app"
        }
      }

      nat_pools = {
        "rdp-vmss" = {
          frontend_ip_configuration_name = "app"
          frontend_port_start            = 51000
          frontend_port_end              = 51019
          backend_port                   = 3389
        }
      }
    }
  }
}
