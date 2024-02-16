#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "app_secrets" {
  #checkov:skip=CKV_AWS_149:Skip using KMS CMR
  #checkov:skip=CKV2_AWS_57:Skip auto-rotation
  name                           = "azure-app-${local.kebab_name}"
  recovery_window_in_days        = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    "AUTH__CallbackUrl"   = jsonencode(var.redirect_uris)
    "AUTH__IssuerUrl"     = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
    "AUTH__ClientId"      = azuread_application.main_app.client_id
    "AUTH__ClientSecret"  = azuread_application_password.main_app.value
    "AUTH__TenantId"      = data.azuread_client_config.current.tenant_id
    "AUTH__Scopes"        = join(" ", [for k, v in local.ms_graph_scopes : k])
    "AUTH__TokenEndpoint" = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/token"
  })
}
