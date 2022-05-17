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
