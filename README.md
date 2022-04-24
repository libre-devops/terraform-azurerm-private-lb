```hcl
module "network" {
  source = "registry.terraform.io/libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name // rg-ldo-euw-dev-build
  location = module.rg.rg_location
  tags     = local.tags

  vnet_name     = "vnet-${var.short}-${var.loc}-${terraform.workspace}-01" // vnet-ldo-euw-dev-01
  vnet_location = module.network.vnet_location

  address_space   = ["10.0.0.0/16"]
  subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names    = ["sn1-${module.network.vnet_name}", "sn2-${module.network.vnet_name}", "sn3-${module.network.vnet_name}"] //sn1-vnet-ldo-euw-dev-01

  subnet_service_endpoints = {
    subnet2 = ["Microsoft.Storage", "Microsoft.Sql"], // Adds extra subnet endpoints
    subnet3 = ["Microsoft.AzureActiveDirectory"]
  }
}

module "private_lb" {
  source = "github.com/libre-devops/terraform-azurerm-private-lb"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  lb_frontend_ip_configurations = {
    "lbi-${var.short}-${var.loc}-${terraform.workspace}-01-ipconfig" = {
      subnet_id                     = element(values(module.network.subnets_ids), 2),
      private_ip_address_allocation = "Dynamic"
    },
  }

  lb_name                  = "lbi-${var.short}-${var.loc}-${terraform.workspace}-01" // lbi-ldo-euw-dev-01
  lb_bpool_name            = "bpool-${module.public_lb.lb_name}"
}

```

For a full example build, check out the [Libre DevOps Website](https://www.libredevops.org/quickstart/utils/terraform/using-lbdo-tf-modules-example.html)

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_lb.priv_lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.private_lb_bpool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lb_bpool_name"></a> [lb\_bpool\_name](#input\_lb\_bpool\_name) | The name for the backend pool for the Load Balancer | `string` | n/a | yes |
| <a name="input_lb_frontend_ip_configurations"></a> [lb\_frontend\_ip\_configurations](#input\_lb\_frontend\_ip\_configurations) | Load Balancer frontend config | `map(any)` | `{}` | no |
| <a name="input_lb_name"></a> [lb\_name](#input\_lb\_name) | The name of the LB | `string` | n/a | yes |
| <a name="input_lb_sku_name"></a> [lb\_sku\_name](#input\_lb\_sku\_name) | The SKU of the lb | `string` | `"Standard"` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for this resource to be put in | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | <pre>{<br>  "source": "terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bpool_id"></a> [bpool\_id](#output\_bpool\_id) | The id of the backend pool |
| <a name="output_bpool_name"></a> [bpool\_name](#output\_bpool\_name) | The name of the backend pool |
| <a name="output_lb_id"></a> [lb\_id](#output\_lb\_id) | The ID of the load balancer |
| <a name="output_lb_ip_configuration"></a> [lb\_ip\_configuration](#output\_lb\_ip\_configuration) | The frontend ip configuration object |
| <a name="output_lb_name"></a> [lb\_name](#output\_lb\_name) | The Name of the load balancer |
