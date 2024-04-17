locals {
  api_apps = { for app in var.api_apps : app => app }
}

# for exporting the api_apps information
data "azuread_application" "api_apps" {
  for_each     = local.api_apps
  display_name = each.key
}

# for adding spa client app to the api app
resource "azuread_application_pre_authorized" "known_client_apps" {
  for_each = local.api_apps

  # object id of the app for which permissions are authorized
  application_id = data.azuread_application.api_apps[each.key].id

  # client id of the application being authorized
  authorized_client_id = azuread_application.main_app.client_id

  # permission scope IDs required by the authorized application
  permission_ids = values(data.azuread_application.api_apps[each.key].oauth2_permission_scope_ids)
}

# for adding permissions to the spa app for accessing web api
resource "azuread_application_api_access" "scope_access_to_api" {
  for_each = local.api_apps

  application_id = azuread_application.main_app.id
  api_client_id  = data.azuread_application.api_apps[each.key].client_id

  scope_ids = values(data.azuread_application.api_apps[each.key].oauth2_permission_scope_ids)
}
