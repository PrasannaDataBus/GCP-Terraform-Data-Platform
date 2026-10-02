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
    prefix = "domains/dev/h1_gci_customer"
  }
}

provider "google" {}

# BRONZE (RAW) ZONE - Airflow Ingestion
module "gci_customer_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_raw_gci_customer"
  cost_center      = "customer_engineering"
  data_sensitivity = "pii"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:airflow-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
  dataset_viewers = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# SILVER ZONE - dbt Transformations
module "gci_customer_silver_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  dataset_id       = "dev_silver_gci_customer"
  cost_center      = "customer_engineering"
  data_sensitivity = "pii"
  environment      = "dev"
  is_temp_sandbox  = true

  dataset_editors = [
    "serviceAccount:dbt-dev-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}

# STREAMING



# REAL-TIME ZONE - Pub/Sub and Dataflow Streaming (Self-Service)

module "gci_customer_streaming_zone" {
  source = "../../../modules/data_platform_streaming"

  project_id  = "gcp-terraform-tmp"
  domain_name = "gci_customer"
  environment = "dev"
  cost_center = "customer_engineering"
  topic_name  = "operational-events"
}
