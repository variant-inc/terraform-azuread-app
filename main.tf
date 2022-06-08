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
}

resource "random_uuid" "role_uuid" {
  for_each = local.uuid_roles
}

resource "random_uuid" "app_uri" {
}

data "azuread_user" "owner" {
  count               = length(var.owners)
  user_principal_name = var.owners[count.index]
}

data "azuread_client_config" "current" {}

resource "azuread_application" "app" {
  display_name    = local.kebab_name
  identifier_uris = ["api://${random_uuid.app_uri.result}-${var.name}"]
  owners          = [data.azuread_client_config.current.object_id]

  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2
  }

  dynamic "app_role" {
    for_each = local.roles
    content {
      allowed_member_types = ["User"]
      description          = "Role - ${app_role.key}"
      enabled              = true
      id                   = app_role.value
      display_name         = app_role.key
      value                = app_role.key
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # OpenID
      type = "Scope"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }
  }

  web {
    redirect_uris = var.redirect_uris
    homepage_url  = var.homepage_url
    logout_url    = var.logout_url

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_application_password" "app_client_secret" {
  application_object_id = azuread_application.app.object_id
}

resource "azuread_service_principal" "enterprise_app" {
  application_id               = azuread_application.app.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
  notes                        = jsonencode(var.tags)

  feature_tags {
    enterprise = true
  }
}

resource "azuread_group" "groups" {
  for_each = local.groups

  display_name     = "${var.name}-${each.key}"
  owners           = concat([data.azuread_client_config.current.object_id], data.azuread_user.owner[*].object_id)
  security_enabled = true
}

resource "azuread_app_role_assignment" "app_role_assignment" {
  for_each = local.groups_assignment

  app_role_id         = azuread_application.app.app_role_ids[each.value.role]
  principal_object_id = azuread_group.groups[each.value.group].object_id
  resource_object_id  = azuread_service_principal.enterprise_app.object_id
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name = "azure-app-${local.kebab_name}"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    "callback_url" : var.redirect_uris,
    "auth_url" : "https:login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize",
    "access_token_url" : "https:login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token",
    "client_id" : azuread_application.app.application_id,
    "client_secret" : azuread_application_password.app_client_secret.value,
    "scope" : ["open_id", "profile", "email"]
  })
}