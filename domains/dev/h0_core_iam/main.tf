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

# ========================================================================================
# H1 - Airflow
# ========================================================================================

# Provision the isolated Service Account for Local Airflow - H1
resource "google_service_account" "airflow_dev_worker" {
  account_id   = "airflow-dev-worker"
  display_name = "Airflow Dev Orchestration Worker"
  description  = "Used by local Airflow-dev Docker to write to Dev BigQuery datasets"
}

# Grant Job User role at the project level so Airflow can execute queries - H1
resource "google_project_iam_member" "airflow_dev_bq_job_user" {
  project = "gcp-terraform-tmp"
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.airflow_dev_worker.email}"
}

# Output the exact email address so we can use it in our landing zones - H1
output "airflow_dev_sa_email" {
  value = google_service_account.airflow_dev_worker.email
}

# ========================================================================================
# H1 - dbt
# ========================================================================================

# DBT WORKER IDENTITY

# Provision the isolated Service Account for local dbt - H1
resource "google_service_account" "dbt_dev_worker" {
  account_id   = "dbt-dev-worker"
  display_name = "dbt Dev Transformation Worker"
  description  = "Used by local dbt to read raw datasets and materialize refined datasets"
}

# Grant Job User role at the project level so dbt can execute SQL compute jobs - H1
resource "google_project_iam_member" "dbt_dev_bq_job_user" {
  project = "gcp-terraform-tmp"
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt_dev_worker.email}"
}

output "dbt_dev_sa_email" {
  value = google_service_account.dbt_dev_worker.email
}

# ========================================================================================
# H2 - Airflow
# ========================================================================================

# Provision the isolated Service Account for Local Airflow - H2
resource "google_service_account" "airflow_dev_h2_bv_worker" {
  account_id   = "airflow-dev-h2-bv-worker"
  display_name = "Airflow Dev Orchestration Worker for h2 bv"
  description  = "Used by local Airflow-dev Docker to write to Dev BigQuery datasets"
}

# Grant Job User role at the project level so Airflow can execute queries - H2
resource "google_project_iam_member" "airflow_dev_h2_bv_bq_job_user" {
  project = "gcp-terraform-tmp"
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.airflow_dev_h2_bv_worker.email}"
}

# Output the exact email address so we can use it in our landing zones - H2
output "airflow_dev_sa_h2_bv_email" {
  value = google_service_account.airflow_dev_h2_bv_worker.email
}

# ========================================================================================
# H2 - dbt
# ========================================================================================

# DBT WORKER IDENTITY - H2

# Provision the isolated Service Account for local dbt - H2
resource "google_service_account" "dbt_dev_h2_bv_worker" {
  account_id   = "dbt-dev-h2-bv-worker"
  display_name = "dbt Dev h2 bv Transformation Worker"
  description  = "Used by local dbt to read raw datasets and materialize refined datasets"
}

# Grant Job User role at the project level so dbt can execute SQL compute jobs - H2
resource "google_project_iam_member" "dbt_dev_h2_bv_bq_job_user" {
  project = "gcp-terraform-tmp"
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt_dev_h2_bv_worker.email}"
}

output "dbt_dev_sa_h2_bv_email" {
  value = google_service_account.dbt_dev_h2_bv_worker.email
}
