locals {
  kebab_name = "dx-${var.environment}-${var.name}"

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

  api_apps = { for app in var.api_apps : app => app }

  # false -> non-admin
  # true -> grant admin access
  ms_graph_scopes = {
    "openid" : false,
    "email" : false,
    "profile" : false,
    "offline_access" : false,
    "User.Read" : true,
    "Group.Read.All" : true,
    "User.Read.All" : true
  }

  optional_claims = [
    "acct",
    "auth_time",
    "ctry",
    "email",
    "family_name",
    "fwd",
    "given_name",
    "in_corp",
    "ipaddr",
    "login_hint",
    "onprem_sid",
    "preferred_username",
    "pwd_exp",
    "pwd_url",
    "sid",
    "tenant_ctry",
    "tenant_region_scope",
    "upn",
    "verified_primary_email",
    "verified_secondary_email",
    "vnet",
    "xms_pdl",
    "xms_pl",
    "xms_tpl",
    "ztdid"
  ]
}

resource "random_uuid" "role_uuid" {
  for_each = local.uuid_roles
}

resource "random_uuid" "app_scope" {
}

# for exporting the groups provided in the variables
data "azuread_group" "groups" {
  for_each     = local.groups
  display_name = each.key
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_client_config" "current" {}

# for exporting the api_apps information
data "azuread_application" "api_apps" {
  for_each     = local.api_apps
  display_name = each.key
}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_application" "main_app" {

  display_name            = local.kebab_name
  identifier_uris         = ["api://${local.kebab_name}"]
  owners                  = [data.azuread_client_config.current.object_id]
  group_membership_claims = ["All"]

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

  optional_claims {
    dynamic "access_token" {
      for_each = toset(local.optional_claims)
      content {
        name = access_token.value
      }
    }
    access_token {
      name = "groups"
      additional_properties = [
        "cloud_displayname",
        "sam_account_name"
      ]
    }
    dynamic "id_token" {
      for_each = toset(local.optional_claims)
      content {
        name = id_token.value
      }
    }
    id_token {
      name = "groups"
      additional_properties = [
        "cloud_displayname",
        "sam_account_name"
      ]
    }
  }

  required_resource_access {
    # Microsoft Graph
    resource_app_id = azuread_service_principal.msgraph.application_id
    dynamic "resource_access" {
      for_each = local.ms_graph_scopes
      content {
        id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids[resource_access.key]
        type = "Scope"
      }
    }
  }

  # for adding permissions to the spa app for accessing web api
  dynamic "required_resource_access" {
    for_each = local.api_apps
    content {
      resource_app_id = data.azuread_application.api_apps[required_resource_access.key].application_id

      dynamic "resource_access" {
        for_each = values(data.azuread_application.api_apps[required_resource_access.key].oauth2_permission_scope_ids)
        content {
          id   = resource_access.value
          type = "Scope"
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

# Grant Admin access for delegates
resource "azuread_service_principal_delegated_permission_grant" "access" {
  service_principal_object_id          = azuread_service_principal.main_app.object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values                         = [for k, v in local.ms_graph_scopes : k if v]
}

# for adding spa client app to the api app
resource "azuread_application_pre_authorized" "known_client_apps" {
  for_each = local.api_apps

  # object id of the app for which permissions are authorized
  application_object_id = data.azuread_application.api_apps[each.key].object_id

  # client id of the application being authorized
  authorized_app_id = azuread_application.main_app.application_id

  # permission scope IDs required by the authorized application
  permission_ids = values(data.azuread_application.api_apps[each.key].oauth2_permission_scope_ids)
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

# for assigning app roles to the provided groups
resource "azuread_app_role_assignment" "main_app" {
  for_each = local.groups_assignment

  app_role_id         = azuread_application.main_app.app_role_ids[each.value.role]
  principal_object_id = data.azuread_group.groups[each.value.group].object_id
  resource_object_id  = azuread_service_principal.main_app.object_id
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name                           = "azure-app-${local.kebab_name}"
  recovery_window_in_days        = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    "AUTH__CallbackUrl"   = jsonencode(var.redirect_uris)
    "AUTH__IssuerUrl"     = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
    "AUTH__ClientId"      = azuread_application.main_app.application_id
    "AUTH__ClientSecret"  = azuread_application_password.main_app.value
    "AUTH__TenantId"         = data.azuread_client_config.current.tenant_id
    "AUTH__Scopes"         = join(" ", [for k, v in local.ms_graph_scopes : k])
    "AUTH__TokenEndpoint" = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/token"
  })
}
