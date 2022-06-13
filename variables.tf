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

variable "owners" {
  description = "The owners of this application"
  type        = list(string)
}

variable "group_roles_assignment" {
  description = "Groups + Roles + Assignment to App"
  type = list(object({
    name  = string
    roles = list(string)
  }))
}

variable "redirect_uris" {
  description = "The redirect URIs where OAuth 2.0 authorization codes and access tokens are sent"
  type        = list(string)
  default     = null
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
