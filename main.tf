locals {
  kebab_name = "dx-${var.environment}-${var.name}"

  distinct_roles = distinct(
    flatten(concat(
      [for g in var.group_roles_assignment : g.roles],
      [for g in var.app_roles_assignment : g.roles],
    ))
  )

  uuid_roles = {
    for x in local.distinct_roles : x => x
  }

  roles = {
    for x in local.distinct_roles : x => random_uuid.role_uuid[x].result
  }

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

  assigned_to_apps = { for app in var.assigned_to_apps : app.name => app }
}

resource "random_uuid" "role_uuid" {
  for_each = local.uuid_roles
}

resource "random_uuid" "app_scope" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_client_config" "current" {}

# for exporting the assigned_to_apps information
data "azuread_application" "assigned_to_apps" {
  for_each     = local.assigned_to_apps
  display_name = each.key
}

resource "azuread_service_principal" "msgraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
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

  lifecycle {
    ignore_changes = [
      required_resource_access,
      app_role
    ]
  }
}

resource "azuread_application_app_role" "app_roles" {
  for_each = local.roles

  application_id       = azuread_application.main_app.id
  allowed_member_types = ["User", "Application"]
  description          = "Role - ${each.key}"
  role_id              = each.value
  display_name         = each.key
  value                = each.key
}

# for adding permissions to ms graph
resource "azuread_application_api_access" "scope_ms_graph" {
  application_id = azuread_application.main_app.id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

  scope_ids = [for k, v in local.ms_graph_scopes : azuread_service_principal.msgraph.oauth2_permission_scope_ids[k]]
}

# Grant Admin access for delegates
resource "azuread_service_principal_delegated_permission_grant" "access" {
  service_principal_object_id          = azuread_service_principal.main_app.object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values                         = [for k, v in local.ms_graph_scopes : k if v]
}

resource "azuread_application_password" "main_app" {
  application_id    = azuread_application.main_app.id
  end_date_relative = "867834h"
}

resource "azuread_service_principal" "main_app" {
  client_id                    = azuread_application.main_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
  notes                        = jsonencode(var.tags)

  feature_tags {
    enterprise = true
  }
}
