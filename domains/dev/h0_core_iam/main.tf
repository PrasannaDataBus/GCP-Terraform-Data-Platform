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
    prefix = "domains/dev/h0_core_iam"
  }
}

provider "google" {
  project = "gcp-terraform-tmp"
  region  = "europe-west1"
}

# Provision the isolated Service Account for Local Airflow
resource "google_service_account" "airflow_dev_worker" {
  account_id   = "airflow-dev-worker"
  display_name = "Airflow Dev Orchestration Worker"
  description  = "Used by local Airflow-dev Docker to write to Dev BigQuery datasets"
}

# Grant Job User role at the project level so Airflow can execute queries
resource "google_project_iam_member" "airflow_dev_bq_job_user" {
  project = "gcp-terraform-tmp"
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.airflow_dev_worker.email}"
}

# Output the exact email address so we can use it in our landing zones
output "airflow_dev_sa_email" {
  value = google_service_account.airflow_dev_worker.email
}