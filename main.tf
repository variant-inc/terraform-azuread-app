locals {
  kebab_name = "${var.environment}-${var.name}"

  distinct_roles = distinct(
    flatten(
      [for g in var.group_roles_assignment : g.roles]
    )
  )

  uuid_roles = {
    for x in local.distinct_roles : x => x
  }

  roles = {
    for x in local.distinct_roles : x => random_uuid.role_uuid[x].result
  }

  grp_asgn = flatten([
    for _group in var.group_roles_assignment : [
      for _role in _group.roles : ([
        {
          group = _group.name
          role  = _role
        }
      ])
    ]
  ])

  groups_assignment = {
    for x in local.grp_asgn :
    "${x.group}-${x.role}" => x
  }

  groups = {
    for x in flatten([for g in var.group_roles_assignment : g.name]) :
    x => x
  }

  service_app_assignment = {
    for i in var.service_app_roles_assignment : i.name => ({
      app = i.name
    roles = ({ for role in i.roles : role => role }) })
  }


  s_a = flatten([
    for app in var.service_app_roles_assignment : [
      for r in app.roles : ([
        {
          app  = app.name
          role = r
        }
      ])
    ]
  ])

  admin_grant_roles = { for i in local.s_a : "${i.app}-${i.role}" => i }

  api_apps = { for app in var.api_apps : app => app }
}

resource "random_uuid" "role_uuid" {
  for_each = local.uuid_roles
}

resource "random_uuid" "app_scope" {
}

data "azuread_group" "groups" { # for exporting the groups provided in the variables
  for_each     = local.groups
  display_name = each.key
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_client_config" "current" {}

data "azuread_application" "api_apps" { # for exporting the api_apps information
  for_each     = local.api_apps
  display_name = each.key
}

data "azuread_application" "service_apps" { # for exporting the service apps information
  for_each     = local.service_app_assignment
  display_name = each.key
}

data "azuread_service_principal" "service_apps" { # for exporting the service_apps service principle information
  for_each     = local.service_app_assignment
  display_name = each.key
}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_application" "main_app" {

  display_name    = local.kebab_name
  identifier_uris = ["api://${local.kebab_name}"]
  owners          = [data.azuread_client_config.current.object_id]

  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access example on behalf of the signed-in user."
      admin_consent_display_name = "Access example"
      enabled                    = true
      id                         = random_uuid.app_scope.result
      type                       = "User"
      user_consent_description   = "Allow the application to access example on your behalf."
      user_consent_display_name  = "Access example"
      value                      = "user_impersonation"
    }
  }

  dynamic "app_role" {
    for_each = local.roles
    content {
      allowed_member_types = ["User", "Application"]
      description          = "Role - ${app_role.key}"
      enabled              = true
      id                   = app_role.value
      display_name         = app_role.key
      value                = app_role.key
    }
  }

  required_resource_access {
    resource_app_id = azuread_service_principal.msgraph.application_id # Microsoft Graph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["openid"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["email"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["profile"]
      type = "Scope"
    }
  }

  dynamic "required_resource_access" { # for adding permissions to the spa app for accessing web api
    for_each = local.api_apps
    content {
      resource_app_id = data.azuread_application.api_apps[required_resource_access.key].application_id

      resource_access {
        id   = data.azuread_application.api_apps[required_resource_access.key].oauth2_permission_scope_ids["user_impersonation"]
        type = "Scope"
      }
    }
  }

  dynamic "required_resource_access" { # for service to service calls
    for_each = local.service_app_assignment
    content {
      resource_app_id = data.azuread_application.service_apps[required_resource_access.key].application_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.roles
        content {
          id   = data.azuread_application.service_apps[required_resource_access.key].app_role_ids[resource_access.key]
          type = "Role"
        }
      }
    }
  }

  single_page_application {
    redirect_uris = var.type == "spa" ? var.redirect_uris : []
  }

  web {
    redirect_uris = var.type != "spa" ? var.redirect_uris : []
    homepage_url  = var.homepage_url
    logout_url    = var.logout_url

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_application_pre_authorized" "known_client_apps" { # for adding spa client app to the api app
  for_each              = local.api_apps
  application_object_id = data.azuread_application.api_apps[each.key].object_id                                           # object id of the app for which permissions are authorized
  authorized_app_id     = azuread_application.main_app.application_id                                                     # client id of the application being authorized
  permission_ids        = [data.azuread_application.api_apps[each.key].oauth2_permission_scope_ids["user_impersonation"]] # permission scope IDs required by the authorized application
}

resource "azuread_application_password" "main_app" {
  application_object_id = azuread_application.main_app.object_id
  end_date_relative     = "867834h"
}

resource "azuread_service_principal" "main_app" {
  application_id               = azuread_application.main_app.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
  notes                        = jsonencode(var.tags)

  feature_tags {
    enterprise = true
  }
}

resource "azuread_app_role_assignment" "service_apps" { # for granting the admin consent for service to service authentication
  for_each            = local.admin_grant_roles
  app_role_id         = data.azuread_application.service_apps[each.value.app].app_role_ids[each.value.role] # roles from the application which this app needs access to
  principal_object_id = azuread_service_principal.main_app.object_id                                        # service principal object_id of main app
  resource_object_id  = data.azuread_service_principal.service_apps[each.value.app].object_id               # service principle of the application which this app needs access to
}

resource "azuread_app_role_assignment" "main_app" { # for assigning app roles to the provided groups
  for_each = local.groups_assignment

  app_role_id         = azuread_application.main_app.app_role_ids[each.value.role]
  principal_object_id = data.azuread_group.groups[each.value.group].object_id
  resource_object_id  = azuread_service_principal.main_app.object_id
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name = "azure-app-${local.kebab_name}"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = length(var.service_app_roles_assignment) == 0 ? jsonencode({
    "AUTH__callback_url"     = var.redirect_uris
    "AUTH__auth_url"         = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize"
    "AUTH__access_token_url" = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token"
    "AUTH__client_id"        = azuread_application.main_app.application_id
    "AUTH__client_secret"    = azuread_application_password.main_app.value
    "AUTH__scope"            = concat(["open_id", "profile", "email"], var.api_apps != null ? [for app_name in var.api_apps : format("api://%s", app_name)] : []) # adding backend api app scopes only if they are supplied
    }) : jsonencode({                                                                                                                                             # if we have service to service calls
    "AUTH__callback_url"                                 = var.redirect_uris
    "AUTH__auth_url"                                     = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize"
    "AUTH__access_token_url"                             = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token"
    "AUTH__client_id"                                    = azuread_application.main_app.application_id
    "AUTH__client_secret"                                = azuread_application_password.main_app.value
    "AUTH__scope"                                        = concat(["open_id", "profile", "email"], var.api_apps != null ? [for app_name in var.api_apps : format("api://%s", app_name)] : []) # adding backend api app scopes only if they are supplied
    "AUTH__resources"                                    = { for a, b in local.service_app_assignment : a => format("api://%s", b.app) }
    "AUTH__access_token_url_for_client_credentials_flow" = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/token"
  })

}