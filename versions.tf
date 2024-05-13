terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0, <6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
