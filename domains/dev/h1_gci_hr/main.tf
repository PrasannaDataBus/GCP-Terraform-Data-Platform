terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4.0"
    }
  }
  backend "gcs" {
    bucket = "gcp-terraform-tmp-tfstate-prasanna"
    prefix = "domains/dev/h1_gci_hr"
  }
}

provider "google" {}

# BRONZE (RAW) ZONE - Airflow Writes, dbt Reads

module "gci_hr_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_raw_gci_hr"
  location         = "EU"
  cost_center      = "gci_hr_global"
  data_sensitivity = "confidential"
  environment      = "dev"
  is_temp_sandbox  = false

  dataset_editors = [
    "serviceAccount:airflow-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
  dataset_viewers = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# SILVER ZONE - dbt Transforms & Writes

module "gci_hr_silver_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_silver_gci_hr"
  location         = "EU"
  cost_center      = "gci_hr_global"
  data_sensitivity = "confidential"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}