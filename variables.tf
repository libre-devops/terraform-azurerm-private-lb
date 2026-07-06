variable "lbs" {
  description = <<-EOT
    Internal (private) load balancers to create, keyed by load balancer name. Every frontend is a
    private frontend on a subnet; use the public-lb module for internet-facing frontends. Fields:
      sku        Standard (default) or Gateway (a Gateway Load Balancer for NVA chaining). Basic is
                 retired and rejected.
      sku_tier   Regional only: the Global tier (cross-region load balancer) supports public
                 frontends only, so it lives in the public-lb module.
      edge_zone  Edge Zone the load balancer lives in.
      tags       Per-load-balancer tags (falls back to the module tags when null).
      frontend_ip_configurations  Private frontends keyed by frontend name. subnet_id is required.
                 private_ip_address pins a static address (allocation flips to Static
                 automatically). zones defaults to zone-redundant ["1", "2", "3"] on Standard;
                 Gateway frontends do not take zones, so the default there is none. Set zones = []
                 explicitly for regions without availability zones.
      backend_pools  Backend address pools keyed by pool name. virtual_network_id enables
                 IP-based backends (with optional synchronous_mode); addresses is a map of
                 IP-based backend addresses keyed by address name; tunnel_interfaces is for
                 Gateway SKU pools only.
      probes     Health probes keyed by probe name. protocol defaults to Tcp; Http and Https
                 require request_path.
      rules      Load-balancing rules keyed by rule name. Reference module-built objects by key
                 (backend_pool_keys, probe_key) or pass raw ids (backend_address_pool_ids,
                 probe_id). frontend_ip_configuration_name may be omitted when the load balancer
                 has exactly one frontend. HA-ports (protocol All, ports 0) is supported, it is an
                 internal-load-balancer-only feature.
      nat_rules  Inbound NAT rules keyed by rule name: either a single frontend_port, or a
                 frontend_port_start/frontend_port_end range targeting a backend pool (by
                 backend_pool_key or backend_address_pool_id).
      nat_pools  Legacy inbound NAT pools keyed by pool name (superseded by port-range NAT rules;
                 kept for VMSS setups that still need them).
  EOT
  type = map(object({
    sku       = optional(string, "Standard")
    sku_tier  = optional(string, "Regional")
    edge_zone = optional(string)
    tags      = optional(map(string))

    frontend_ip_configurations = map(object({
      subnet_id                                          = string
      private_ip_address                                 = optional(string)
      private_ip_address_allocation                      = optional(string)
      private_ip_address_version                         = optional(string, "IPv4")
      zones                                              = optional(set(string))
      gateway_load_balancer_frontend_ip_configuration_id = optional(string)
    }))

    backend_pools = optional(map(object({
      virtual_network_id = optional(string)
      synchronous_mode   = optional(string)
      tunnel_interfaces = optional(list(object({
        identifier = number
        type       = string
        protocol   = string
        port       = number
      })), [])
      addresses = optional(map(object({
        virtual_network_id                  = optional(string)
        ip_address                          = optional(string)
        backend_address_ip_configuration_id = optional(string)
      })), {})
    })), {})

    probes = optional(map(object({
      protocol            = optional(string, "Tcp")
      port                = number
      request_path        = optional(string)
      interval_in_seconds = optional(number)
      number_of_probes    = optional(number)
      probe_threshold     = optional(number)
    })), {})

    rules = optional(map(object({
      protocol                       = optional(string, "Tcp")
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = optional(string)
      backend_pool_keys              = optional(list(string), [])
      backend_address_pool_ids       = optional(list(string), [])
      probe_key                      = optional(string)
      probe_id                       = optional(string)
      floating_ip_enabled            = optional(bool)
      tcp_reset_enabled              = optional(bool)
      idle_timeout_in_minutes        = optional(number)
      load_distribution              = optional(string)
      disable_outbound_snat          = optional(bool)
    })), {})

    nat_rules = optional(map(object({
      protocol                       = optional(string, "Tcp")
      backend_port                   = number
      frontend_port                  = optional(number)
      frontend_port_start            = optional(number)
      frontend_port_end              = optional(number)
      backend_pool_key               = optional(string)
      backend_address_pool_id        = optional(string)
      frontend_ip_configuration_name = optional(string)
      floating_ip_enabled            = optional(bool)
      tcp_reset_enabled              = optional(bool)
      idle_timeout_in_minutes        = optional(number)
    })), {})

    nat_pools = optional(map(object({
      protocol                       = optional(string, "Tcp")
      frontend_port_start            = number
      frontend_port_end              = number
      backend_port                   = number
      frontend_ip_configuration_name = optional(string)
      floating_ip_enabled            = optional(bool)
      tcp_reset_enabled              = optional(bool)
      idle_timeout_in_minutes        = optional(number)
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for lb in values(var.lbs) : contains(["Standard", "Gateway"], lb.sku)])
    error_message = "sku must be Standard or Gateway. Basic load balancers are retired (30 September 2025) and cannot be created."
  }

  validation {
    condition     = alltrue([for lb in values(var.lbs) : lb.sku_tier == "Regional"])
    error_message = "sku_tier must be Regional: the Global tier (cross-region load balancer) only supports public frontends, use the public-lb module."
  }

  validation {
    condition     = alltrue([for lb in values(var.lbs) : length(lb.frontend_ip_configurations) > 0])
    error_message = "Every load balancer needs at least one frontend_ip_configuration."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for f in values(lb.frontend_ip_configurations) :
        f.private_ip_address_allocation == null ? true : contains(["Static", "Dynamic"], f.private_ip_address_allocation)
      ]
    ]))
    error_message = "frontend private_ip_address_allocation must be Static or Dynamic."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for p in values(lb.backend_pools) : lb.sku == "Gateway" ? true : length(p.tunnel_interfaces) == 0
      ]
    ]))
    error_message = "tunnel_interfaces on a backend pool are only valid when the load balancer sku is Gateway."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for p in values(lb.backend_pools) : p.synchronous_mode == null ? true : p.virtual_network_id != null
      ]
    ]))
    error_message = "backend pool synchronous_mode requires virtual_network_id to be set on the pool."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for p in values(lb.backend_pools) :
        p.virtual_network_id == null ? true : alltrue([for a in values(p.addresses) : a.virtual_network_id == null])
      ]
    ]))
    error_message = "Azure rejects a virtual network on both the pool and its addresses (IpBasedLbShouldHaveVnetPropertyEitherOnPoolOrBackendAddressLevel): set virtual_network_id on the pool or on each address, never both."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for pr in values(lb.probes) : contains(["Tcp", "Http", "Https"], pr.protocol)
      ]
    ]))
    error_message = "probe protocol must be Tcp, Http, or Https."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for pr in values(lb.probes) : pr.protocol == "Tcp" ? true : pr.request_path != null
      ]
    ]))
    error_message = "Http and Https probes require request_path."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for r in values(lb.rules) : contains(["Tcp", "Udp", "All"], r.protocol)
      ]
    ]))
    error_message = "rule protocol must be Tcp, Udp, or All (All is the HA-ports rule, with frontend_port and backend_port 0)."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for r in values(lb.rules) : r.protocol == "All" ? (r.frontend_port == 0 && r.backend_port == 0) : true
      ]
    ]))
    error_message = "HA-ports rules (protocol All) must use frontend_port = 0 and backend_port = 0."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for r in values(lb.rules) : [
          for key in r.backend_pool_keys : contains(keys(lb.backend_pools), key)
        ]
      ]
    ]))
    error_message = "every rule backend_pool_keys entry must match a key in the load balancer's backend_pools."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for r in values(lb.rules) : r.probe_key == null ? true : contains(keys(lb.probes), r.probe_key)
      ]
    ]))
    error_message = "every rule probe_key must match a key in the load balancer's probes."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for r in concat(values(lb.rules), values(lb.nat_rules), values(lb.nat_pools)) :
        r.frontend_ip_configuration_name == null ? length(lb.frontend_ip_configurations) == 1 : contains(keys(lb.frontend_ip_configurations), r.frontend_ip_configuration_name)
      ]
    ]))
    error_message = "frontend_ip_configuration_name must name a frontend key, and may only be omitted when the load balancer has exactly one frontend."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for nr in values(lb.nat_rules) :
        (nr.frontend_port != null && nr.frontend_port_start == null && nr.frontend_port_end == null && nr.backend_pool_key == null && nr.backend_address_pool_id == null) ||
        (nr.frontend_port == null && nr.frontend_port_start != null && nr.frontend_port_end != null && (nr.backend_pool_key != null || nr.backend_address_pool_id != null))
      ]
    ]))
    error_message = "a NAT rule is either single-port (frontend_port only) or a port range (frontend_port_start and frontend_port_end plus a backend pool via backend_pool_key or backend_address_pool_id)."
  }

  validation {
    condition = alltrue(flatten([
      for lb in values(var.lbs) : [
        for nr in values(lb.nat_rules) : nr.backend_pool_key == null ? true : contains(keys(lb.backend_pools), nr.backend_pool_key)
      ]
    ]))
    error_message = "every NAT rule backend_pool_key must match a key in the load balancer's backend_pools."
  }
}

variable "location" {
  description = "Azure region for the load balancers."
  type        = string
}

variable "resource_group_id" {
  description = "Resource id of the resource group the load balancers are created in. The resource group name and subscription are parsed from this id."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group resource id."
  }
}

variable "tags" {
  description = "Tags applied to the load balancers (unless a load balancer sets its own)."
  type        = map(string)
  default     = {}
}
