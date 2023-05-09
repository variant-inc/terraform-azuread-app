# Azure AD SPA App

<!-- markdownlint-disable MD033 MD013 MD041 -->

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.15 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 2.15 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.app_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.app_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [azuread_app_role_assignment.main_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_app_role_assignment.service_apps](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.main_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.main_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_application_pre_authorized.known_client_apps](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_pre_authorized) | resource |
| [azuread_service_principal.main_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal.msgraph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [random_uuid.app_scope](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [random_uuid.role_uuid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [azuread_application.api_apps](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application) | data source |
| [azuread_application.service_apps](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application) | data source |
| [azuread_application_published_app_ids.well_known](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_published_app_ids) | data source |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azuread_group.groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azuread_service_principal.service_apps](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_apps"></a> [api\_apps](#input\_api\_apps) | The names of the backend API apps if you are creating a frontend spa app | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment of Azure app. | `string` | n/a | yes |
| <a name="input_group_roles_assignment"></a> [group\_roles\_assignment](#input\_group\_roles\_assignment) | Names of the Groups + Roles + Assignment to App | <pre>list(object({<br>    name  = string<br>    roles = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_homepage_url"></a> [homepage\_url](#input\_homepage\_url) | (Optional) Home page or landing page of the application | `string` | `null` | no |
| <a name="input_logout_url"></a> [logout\_url](#input\_logout\_url) | (Optional) The URL that will be used to sign out a user | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of application using the Azure app. | `string` | n/a | yes |
| <a name="input_redirect_uris"></a> [redirect\_uris](#input\_redirect\_uris) | The redirect URIs where OAuth 2.0 authorization codes and access tokens are sent | `list(string)` | `[]` | no |
| <a name="input_service_app_roles_assignment"></a> [service\_app\_roles\_assignment](#input\_service\_app\_roles\_assignment) | Names of the external Azure AD apps + Roles that this app needs access to | <pre>list(object({<br>    name  = string<br>    roles = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags (user + octopus) to assign to all resources | `map(string)` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | Type of Azure app. Either a spa or api app | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app"></a> [app](#output\_app) | Azure App details |
| <a name="output_app_aws_secrets_name"></a> [app\_aws\_secrets\_name](#output\_app\_aws\_secrets\_name) | The Amazon Secret Manager name of the Azure app's secrets. |
| <a name="output_app_name"></a> [app\_name](#output\_app\_name) | Azure App display name. |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | The Application(client) ID of the Azure application. |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | Azure AD Tenant Id. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
