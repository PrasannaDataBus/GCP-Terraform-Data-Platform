terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4.0"
    }
  }

  backend "gcs" {
    bucket = "{{ cookiecutter.tfstate_gcs_bucket }}"
    prefix = "domains/{{ cookiecutter.environment }}/h1_{{ cookiecutter.domain_slug }}"
  }
}

provider "google" {}

# BRONZE (RAW) ZONE - Airflow Ingestion
module "{{ cookiecutter.domain_slug }}_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "{{ cookiecutter.gcp_project_id }}"
  dataset_id       = "{{ cookiecutter.environment }}_raw_{{ cookiecutter.domain_slug }}"
  cost_center      = "{{ cookiecutter.cost_center }}"
  data_sensitivity = "{{ cookiecutter.data_sensitivity }}"
  environment      = "{{ cookiecutter.environment }}"
  is_temp_sandbox  = {{ cookiecutter.is_temp_sandbox }}

  dataset_editors = [
    "serviceAccount:{{ cookiecutter.airflow_worker_sa }}"
  ]
  dataset_viewers = [
    "serviceAccount:{{ cookiecutter.dbt_worker_sa }}"
  ]
}

# SILVER ZONE - dbt Transformations
module "{{ cookiecutter.domain_slug }}_silver_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "{{ cookiecutter.gcp_project_id }}"
  dataset_id       = "{{ cookiecutter.environment }}_silver_{{ cookiecutter.domain_slug }}"
  cost_center      = "{{ cookiecutter.cost_center }}"
  data_sensitivity = "{{ cookiecutter.data_sensitivity }}"
  environment      = "{{ cookiecutter.environment }}"
  is_temp_sandbox  = {{ cookiecutter.is_temp_sandbox }}

  dataset_editors = [
    "serviceAccount:{{ cookiecutter.dbt_worker_sa }}"
  ]
}

# STREAMING

{% if cookiecutter.include_realtime_streaming == "yes" %}

# REAL-TIME ZONE - Pub/Sub and Dataflow Streaming (Self-Service)

module "{{ cookiecutter.domain_slug }}_streaming_zone" {
  source = "../../../modules/data_platform_streaming"

  project_id  = "{{ cookiecutter.gcp_project_id }}"
  domain_name = "{{ cookiecutter.domain_slug }}"
  environment = "{{ cookiecutter.environment }}"
  cost_center = "{{ cookiecutter.cost_center }}"
  topic_name  = "operational-events"
}
{% endif %}