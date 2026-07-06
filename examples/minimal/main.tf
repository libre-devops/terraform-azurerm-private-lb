locals {
  location    = lookup(var.regions, var.loc, "uksouth")
  rg_name     = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  vnet_name   = "vnet-${var.short}-${var.loc}-${terraform.workspace}-001"
  lb_name     = "lbi-${var.short}-${var.loc}-${terraform.workspace}-001"
  subnet_name = "snet-app-${local.vnet_name}"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
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
  subnets       = { (local.subnet_name) = { address_prefixes = ["10.0.1.0/24"] } }
}

# Minimal call: one internal load balancer with a zone-redundant dynamic frontend, a backend pool,
# a health probe, and a load-balancing rule. With a single frontend the rule does not need to name
# it.
module "private_lb" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  lbs = {
    (local.lb_name) = {
      frontend_ip_configurations = {
        "internal" = { subnet_id = module.network.subnet_ids[local.subnet_name] }
      }

      backend_pools = { "app" = {} }

      probes = {
        "tcp-8080" = { port = 8080 }
      }

      rules = {
        "app-8080" = {
          frontend_port     = 80
          backend_port      = 8080
          backend_pool_keys = ["app"]
          probe_key         = "tcp-8080"
        }
      }
    }
  }
}
