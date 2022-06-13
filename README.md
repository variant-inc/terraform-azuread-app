# Azure AD SPA App
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.15.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 2.15.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.app_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.app_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [azuread_app_role_assignment.app_role_assignment](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.app_client_secret](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_group.groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_service_principal.enterprise_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [random_uuid.app_uri](https://registry.terraform.io/providers/hashicorp/random/3.1.0/docs/resources/uuid) | resource |
| [random_uuid.role_uuid](https://registry.terraform.io/providers/hashicorp/random/3.1.0/docs/resources/uuid) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azuread_user.owner](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment of Azure app. | `string` | n/a | yes |
| <a name="input_group_roles_assignment"></a> [group\_roles\_assignment](#input\_group\_roles\_assignment) | Groups + Roles + Assignment to App | <pre>list(object({<br>    name  = string<br>    roles = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_homepage_url"></a> [homepage\_url](#input\_homepage\_url) | (Optional) Home page or landing page of the application | `string` | `null` | no |
| <a name="input_logout_url"></a> [logout\_url](#input\_logout\_url) | (Optional) The URL that will be used to sign out a user | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of application using the Azure app. | `string` | n/a | yes |
| <a name="input_owners"></a> [owners](#input\_owners) | The owners of this application | `list(string)` | n/a | yes |
| <a name="input_redirect_uris"></a> [redirect\_uris](#input\_redirect\_uris) | The redirect URIs where OAuth 2.0 authorization codes and access tokens are sent | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags (user + octopus) to assign to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app"></a> [app](#output\_app) | Azure App details |
| <a name="output_app_group_links"></a> [app\_group\_links](#output\_app\_group\_links) | Direct Links for the security groups for the Azure app. |
| <a name="output_app_name"></a> [app\_name](#output\_app\_name) | Azure App display name. |
| <a name="output_app_secrets_arn"></a> [app\_secrets\_arn](#output\_app\_secrets\_arn) | The Amazon Secret Manager ARN of the Azure app's secrets. |
| <a name="output_app_secrets_name"></a> [app\_secrets\_name](#output\_app\_secrets\_name) | The Amazon Secret Manager name of the Azure app's secrets. |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | The Application(client) ID of the Azure application. |
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | Azure App Id. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
