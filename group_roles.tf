locals {
  groups_assignment = {
    for x in flatten([
      for _group in var.group_roles_assignment : [
        for _role in _group.roles : ([
          {
            group = _group.name
            role  = _role
          }
        ])
      ]
    ]) :
    "${x.group}-${x.role}" => x
  }

  groups = {
    for x in flatten([for g in var.group_roles_assignment : g.name]) :
    x => x
  }
}

# for exporting the groups provided in the variables
data "azuread_group" "groups" {
  for_each     = local.groups
  display_name = each.key
}

# for assigning app roles to the provided groups
resource "azuread_app_role_assignment" "main_app" {
  for_each = local.groups_assignment

  app_role_id         = azuread_application_app_role.app_roles[each.value.role].role_id
  principal_object_id = data.azuread_group.groups[each.value.group].object_id
  resource_object_id  = azuread_service_principal.main_app.object_id
}
