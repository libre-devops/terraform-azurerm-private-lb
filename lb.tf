resource "azurerm_lb" "priv_lb" {
  location            = var.location
  name                = var.lb_name
  resource_group_name = var.rg_name

  sku = var.lb_sku_name

  dynamic "frontend_ip_configuration" {
    for_each = var.lb_frontend_ip_configurations
    content {
      name = frontend_ip_configuration.key

      subnet_id                     = lookup(frontend_ip_configuration.value, "subnet_id", null)
      private_ip_address            = lookup(frontend_ip_configuration.value, "private_ip_address", null)
      private_ip_address_allocation = lookup(frontend_ip_configuration.value, "private_ip_address_allocation", "Dynamic")
      zones                         = tolist(lookup(frontend_ip_configuration.value, "zones", null))
    }
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "private_lb_bpool" {
  loadbalancer_id = azurerm_lb.priv_lb.id
  name            = var.lb_bpool_name
}