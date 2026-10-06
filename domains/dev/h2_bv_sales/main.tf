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
    prefix = "domains/dev/h2_bv_sales"
  }
}

provider "google" {}

# BRONZE (RAW) ZONE - Airflow Ingestion
module "sales_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_raw_sales"
  cost_center      = "bv_sales_emea"
  data_sensitivity = "financial"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:airflow-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
  dataset_viewers = [
    "serviceAccount:dbt-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# SILVER ZONE - dbt Transformations
module "sales_silver_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_silver_sales"
  cost_center      = "bv_sales_emea"
  data_sensitivity = "financial"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:dbt-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# STREAMING

