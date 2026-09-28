terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4.0"
    }
  }

  # STATE ISOLATION: Unique GCS prefix for the Sales Domain
  backend "gcs" {
    bucket = "gcp-terraform-tmp-tfstate-prasanna"
    prefix = "domains/dev/h1_gci_sales"
  }
}

provider "google" {
  project = var.project_id
  region  = var.location
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
  default     = "gcp-terraform-tmp"
}

variable "location" {
  type        = string
  description = "GCP Deployment Region"
  default     = "EU"
}

# REUSING THE PLATFORM MODULE
module "sales_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = var.project_id
  dataset_id       = "dev_raw_sales_emea"
  location         = var.location
  cost_center      = "sales_emea_retail"
  data_sensitivity = "confidential"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:airflow-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# Outputs
output "sales_dataset_id" {
  value       = module.sales_landing_zone.dataset_id
  description = "Provisioned Sales BigQuery Dataset ID"
}