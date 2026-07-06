# Plan-time tests for the module. The provider is mocked, so no credentials, no features block,
# and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  location          = "uksouth"
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01"

  lbs = {
    "lbi-ldo-uks-tst-01" = {
      frontend_ip_configurations = {
        "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" }
      }
      backend_pools = { "app" = {} }
      probes        = { "tcp-8080" = { port = 8080 } }
      rules = {
        "app-8080" = {
          frontend_port     = 80
          backend_port      = 8080
          backend_pool_keys = ["app"]
          probe_key         = "tcp-8080"
        }
      }
      nat_rules = {
        "rule-ssh" = { frontend_port = 2222, backend_port = 22 }
      }
    }
  }
}

# Secure and HA defaults: Standard SKU, zone-redundant frontend, static allocation only when an
# address is pinned, and the children are wired together by key.
run "creates_lb_with_defaults" {
  command = plan

  assert {
    condition     = azurerm_lb.this["lbi-ldo-uks-tst-01"].sku == "Standard"
    error_message = "The load balancer should default to the Standard SKU."
  }

  assert {
    condition     = tolist(azurerm_lb.this["lbi-ldo-uks-tst-01"].frontend_ip_configuration[0].zones) == tolist(["1", "2", "3"])
    error_message = "Standard frontends should be zone-redundant by default."
  }

  assert {
    condition     = azurerm_lb.this["lbi-ldo-uks-tst-01"].frontend_ip_configuration[0].private_ip_address_allocation == "Dynamic"
    error_message = "Frontends without a pinned address should default to Dynamic allocation."
  }

  assert {
    condition     = azurerm_lb_rule.this["lbi-ldo-uks-tst-01/app-8080"].frontend_ip_configuration_name == "internal"
    error_message = "A rule on a single-frontend load balancer should default to that frontend."
  }

  assert {
    condition     = length(azurerm_lb_backend_address_pool.this) == 1 && length(azurerm_lb_probe.this) == 1 && length(azurerm_lb_nat_rule.this) == 1
    error_message = "Each child map entry should create exactly one child resource."
  }
}

# Pinning a frontend address flips the allocation to Static automatically.
run "pinned_address_is_static" {
  command = plan

  variables {
    lbs = {
      "lbi-ldo-uks-tst-01" = {
        frontend_ip_configurations = {
          "internal" = {
            subnet_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01"
            private_ip_address = "10.0.1.10"
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_lb.this["lbi-ldo-uks-tst-01"].frontend_ip_configuration[0].private_ip_address_allocation == "Static"
    error_message = "Pinning private_ip_address should force Static allocation."
  }
}

# The resource group is parsed from the id and exposed as an output.
run "parses_resource_group" {
  command = plan

  assert {
    condition     = output.resource_group_name == "rg-ldo-uks-tst-01"
    error_message = "resource_group_name should be parsed from resource_group_id."
  }
}

# Validation: Basic is retired and rejected.
run "rejects_basic_sku" {
  command = plan

  variables {
    lbs = {
      "lbi-ldo-uks-tst-01" = {
        sku = "Basic"
        frontend_ip_configurations = {
          "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" }
        }
      }
    }
  }

  expect_failures = [var.lbs]
}

# Validation: an HA-ports rule must use port 0 on both sides.
run "rejects_bad_ha_ports_rule" {
  command = plan

  variables {
    lbs = {
      "lbi-ldo-uks-tst-01" = {
        frontend_ip_configurations = {
          "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" }
        }
        rules = {
          "bad-ha" = { protocol = "All", frontend_port = 443, backend_port = 443 }
        }
      }
    }
  }

  expect_failures = [var.lbs]
}

# Validation: a rule may only omit the frontend name when the LB has exactly one frontend.
run "rejects_ambiguous_frontend" {
  command = plan

  variables {
    lbs = {
      "lbi-ldo-uks-tst-01" = {
        frontend_ip_configurations = {
          "one" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" }
          "two" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-nva-vnet-ldo-uks-tst-01" }
        }
        rules = {
          "ambiguous" = { frontend_port = 80, backend_port = 8080 }
        }
      }
    }
  }

  expect_failures = [var.lbs]
}

# Validation: a NAT rule cannot mix single-port and port-range forms.
run "rejects_mixed_nat_rule" {
  command = plan

  variables {
    lbs = {
      "lbi-ldo-uks-tst-01" = {
        frontend_ip_configurations = {
          "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" }
        }
        nat_rules = {
          "bad" = { frontend_port = 2222, frontend_port_start = 50000, frontend_port_end = 50010, backend_port = 22 }
        }
      }
    }
  }

  expect_failures = [var.lbs]
}

# Validation: tunnel interfaces demand the Gateway SKU.
run "rejects_tunnel_interfaces_on_standard" {
  command = plan

  variables {
    lbs = {
      "lbi-ldo-uks-tst-01" = {
        frontend_ip_configurations = {
          "internal" = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Network/virtualNetworks/vnet-ldo-uks-tst-01/subnets/snet-app-vnet-ldo-uks-tst-01" }
        }
        backend_pools = {
          "nva" = {
            tunnel_interfaces = [{ identifier = 900, type = "Internal", protocol = "VXLAN", port = 10800 }]
          }
        }
      }
    }
  }

  expect_failures = [var.lbs]
}
