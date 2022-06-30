output "app" {
  description = "Azure App details"
  value       = azuread_application.app
}

output "app_name" {
  description = "Azure App display name."
  value       = var.name
}

output "object_id" {
  description = "Azure App Id."
  value       = azuread_application.app.object_id
}

output "client_id" {
  description = "The Application(client) ID of the Azure application."
  value       = azuread_application.app.application_id
}

output "application_id_uri" {
  description = "The Application ID URI of the Azure application."
  value       = "api://${random_uuid.app_uri.result}-${var.name}"
}

output "service_apps_client_id" {
  description = "The Application(client) ID of the Azure service applications."
  value       = { for k, v in azuread_application.service_apps : k => v.object_id }
}

output "app_group_links" {
  description = "Direct Links for the security groups for the Azure app."
  value       = { for k, v in azuread_group.groups : k => format("https://portal.azure.com/#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Overview/groupId/%s", v.object_id) }
}

output "app_secrets_arn" {
  description = "The Amazon Secret Manager ARN of the Azure app's secrets."
  value       = aws_secretsmanager_secret_version.app_secret_version.arn
}

output "app_secrets_name" {
  description = "The Amazon Secret Manager name of the Azure app's secrets."
  value       = "azure-app-${var.name}"
}