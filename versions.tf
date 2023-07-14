terraform {
  required_version = ">= 1.3.0"
  backend "s3" {}
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
