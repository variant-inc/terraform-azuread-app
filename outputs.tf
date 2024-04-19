output "app" {
  description = "Azure App details"
  value       = azuread_application.main_app
}

output "app_name" {
  description = "Azure App display name."
  value       = local.kebab_name
}

output "tenant_id" {
  description = "Azure AD Tenant Id."
  value       = data.azuread_client_config.current.tenant_id
}

output "client_id" {
  description = "The Application(client) ID of the Azure application."
  value       = azuread_application.main_app.client_id
}

output "app_aws_secrets_name" {
  description = "The Amazon Secret Manager name of the Azure app's secrets."
  value       = "azure-app-${local.kebab_name}"
}

output "api_apps_scopes" {
  description = "The scopes for API Apps"
  value = merge(
    concat([
      for app in var.api_apps : {
        "AUTH__ApiAppScopes__${app.reference}" = "${data.azuread_application.api_apps[app.name].client_id}/.default"
      }
      ], [
      for app in var.assigned_to_apps : {
        "AUTH__ApiAppScopes__${app.reference}" = "${data.azuread_application.assigned_to_apps[app.name].client_id}/.default"
      }
  ])...)
}
