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
    prefix = "domains/dev/h1_gci_inventory"
  }
}

provider "google" {}

# BRONZE (RAW) ZONE - Airflow Ingestion
module "gci_inventory_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_raw_gci_inventory"
  cost_center      = "gci_inventory_emea"
  data_sensitivity = "internal"
  environment      = "dev"
  is_temp_sandbox  = false

  dataset_editors = [
    "serviceAccount:airflow-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
  dataset_viewers = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# SILVER ZONE - dbt Transformations
module "gci_inventory_silver_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_silver_gci_inventory"
  cost_center      = "gci_inventory_emea"
  data_sensitivity = "internal"
  environment      = "dev"
  is_temp_sandbox  = false

  dataset_editors = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}