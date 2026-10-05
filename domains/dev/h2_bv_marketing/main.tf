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
    prefix = "domains/dev/h2_bv_marketing"
  }
}

provider "google" {}

# BRONZE (RAW) ZONE - Airflow Writes, dbt Reads

module "bv_marketing_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_raw_bv_marketing"
  cost_center      = "bv_marketing_emea"
  data_sensitivity = "pii"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:airflow-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
  dataset_viewers = [
    "serviceAccount:dbt-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# SILVER ZONE - dbt Transforms & Writes

module "bv_marketing_silver_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_silver_bv_marketing"
  cost_center      = "bv_marketing_emea"
  data_sensitivity = "pii"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:dbt-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}