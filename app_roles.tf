locals {
  apps_assignment = {
    for x in flatten([
      for _app in var.app_roles_assignment : [
        for _role in _app.roles : ([
          {
            app  = _app.name
            role = _role
          }
        ])
      ]
    ]) :
    "${x.app}-${x.role}" => x
  }
}

# for exporting the api_apps information
data "azuread_application" "apps_assignment" {
  for_each = {
    for x in var.app_roles_assignment : x.name => x
  }
  display_name = each.value.name
}

data "azuread_service_principal" "apps_assignment" {
  for_each = {
    for x in var.app_roles_assignment : x.name => x
  }
  display_name = each.value.name
}

# for adding permissions to the external app this application
resource "azuread_application_api_access" "role_access_for_other_api" {
  for_each = {
    for x in var.app_roles_assignment : x.name => x
  }

  api_client_id  = azuread_application.main_app.client_id
  application_id = data.azuread_application.apps_assignment[each.key].id

  role_ids = [for role in each.value.roles : local.roles[role]]
}

resource "azuread_app_role_assignment" "role_access_for_other_api" {
  for_each = local.apps_assignment

  app_role_id         = azuread_application_app_role.app_roles[each.value.role].role_id
  principal_object_id = data.azuread_service_principal.apps_assignment[each.value.app].object_id
  resource_object_id  = azuread_service_principal.main_app.object_id
}
