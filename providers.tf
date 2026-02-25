terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

# AWS Providers
provider "aws" {
  region = var.aws_regions[0]
}

provider "aws" {
  alias  = "r2"
  region = var.aws_regions[1]
}

provider "aws" {
  alias  = "r3"
  region = var.aws_regions[2]
}

# Azure Provider
provider "azurerm" {
  features = {}
}

# GCP Providers
provider "google" {
  project = var.gcp_project
  region  = var.gcp_regions[0]
}

provider "google" {
  alias   = "r2"
  project = var.gcp_project
  region  = var.gcp_regions[1]
}

provider "google" {
  alias   = "r3"
  project = var.gcp_project
  region  = var.gcp_regions[2]
}

# OCI Provider
provider "oci" {
  tenancy_ocid = var.oci_tenancy_ocid
  region       = var.oci_regions[0]
}
