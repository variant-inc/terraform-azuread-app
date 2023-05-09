output "app" {
  description = "Azure App details"
  value       = azuread_application.main_app
}

output "app_name" {
  description = "Azure App display name."
  value       = local.kebab_name
}

output "object_id" {
  description = "Azure App Id."
  value       = azuread_application.main_app.object_id
}

output "client_id" {
  description = "The Application(client) ID of the Azure application."
  value       = azuread_application.main_app.application_id
}

output "app_aws_secrets_arn" {
  description = "The Amazon Secret Manager ARN of the Azure app's secrets."
  value       = local.create_secret > 0 ? aws_secretsmanager_secret_version.app_secret_version[0].arn : null
}

output "app_aws_secrets_name" {
  description = "The Amazon Secret Manager name of the Azure app's secrets."
  value       = local.create_secret > 0 ? "azure-app-${var.name}" : null
}
