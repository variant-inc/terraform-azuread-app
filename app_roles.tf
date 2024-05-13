locals {
  assigned_to_apps = { for app in var.assigned_to_apps : app.name => app }

  apps_assignment = {
    for x in flatten([
      for _app in var.assigned_to_apps : [
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

# for exporting the assigned_to_apps information
data "azuread_application" "assigned_to_apps" {
  for_each     = local.assigned_to_apps
  display_name = each.key
}

data "azuread_service_principal" "assigned_to_apps" {
  for_each = {
    for x in var.assigned_to_apps : x.name => x
  }
  display_name = each.value.name
}

# for adding permissions to the external app this application
resource "azuread_application_api_access" "role_access_for_other_api" {
  for_each = {
    for x in var.assigned_to_apps : x.name => x
  }

  api_client_id  = data.azuread_application.assigned_to_apps[each.key].client_id
  application_id = azuread_application.main_app.id

  role_ids = [
    for role in each.value.roles : data.azuread_application.assigned_to_apps[each.key].app_roles[
      index(data.azuread_application.assigned_to_apps[each.key].app_roles[*].display_name, role)
    ].id
  ]
}

resource "azuread_app_role_assignment" "role_access_for_other_api" {
  for_each = local.apps_assignment

  app_role_id = data.azuread_application.assigned_to_apps[each.value.app].app_roles[
    index(data.azuread_application.assigned_to_apps[each.value.app].app_roles[*].display_name, each.value.role)
  ].id

  principal_object_id = azuread_service_principal.main_app.object_id
  resource_object_id  = data.azuread_service_principal.assigned_to_apps[each.value.app].object_id
}
