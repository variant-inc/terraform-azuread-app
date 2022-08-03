variable "name" {
  description = "Name of application using the Azure app."
  type        = string
}

variable "environment" {
  description = "Environment of Azure app."
  type        = string
}

variable "tags" {
  description = "A mapping of tags (user + octopus) to assign to all resources"
  type        = map(string)
}

variable "group_roles_assignment" {
  description = " Names of the Groups + Roles + Assignment to App"
  type = list(object({
    name  = string
    roles = list(string)
  }))
  default = []
}

variable "service_app_roles_assignment" {
  description = "Names of the external Azure AD apps + Roles"
  type = list(object({
    name  = string
    roles = list(string)
  }))
  default = []
}

variable "spa_apps" {
  description = "The names of the frontend spa app if you are creating a backend api app"
  type        = list(string)
  default     = []
}

variable "api_apps" {
  description = "The names of the backend API apps if you are creating a frontend spa app"
  type        = list(string)
  default     = []
}

variable "redirect_uris" {
  description = "The redirect URIs where OAuth 2.0 authorization codes and access tokens are sent"
  type        = list(string)
  default     = []
}

variable "homepage_url" {
  description = "(Optional) Home page or landing page of the application"
  type        = string
  default     = null
}

variable "logout_url" {
  description = "(Optional) The URL that will be used to sign out a user"
  type        = string
  default     = null
}
