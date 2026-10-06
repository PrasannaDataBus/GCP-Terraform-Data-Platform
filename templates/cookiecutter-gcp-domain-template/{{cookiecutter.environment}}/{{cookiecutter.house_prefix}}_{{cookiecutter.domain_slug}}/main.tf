# ==============================================================================
# TERRAFORM CONFIGURATION & STATE MANAGEMENT
# ==============================================================================

terraform {
  # Enforces a minimum Terraform version to guarantee compatibility across the team.
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      # Pulls the official Google provider plugin required to interact with GCP APIs.
      source  = "hashicorp/google"
      # Pins the provider version to avoid breaking changes if a new major version is released.
      version = "~> 8.4.0"
    }
  }

  # Dynamically configures the GCS backend based on Cookiecutter inputs.
  backend "gcs" {
    # Uses the centrally managed bucket for all Terraform state files.
    bucket = "{{ cookiecutter.tfstate_gcs_bucket }}"

    # CRITICAL ZERO-TRUST ISOLATION: The prefix injects both the environment and house_prefix (e.g., dev/h1_gci_marketing).
    # This guarantees that a deployment failure in one brand mathematically cannot corrupt the state of another brand.
    prefix = "domains/{{ cookiecutter.environment }}/{{cookiecutter.house_prefix}}_{{cookiecutter.domain_slug}}"
  }
}

# Initializes the Google provider. Project and region are typically inherited from the environment or core setup.
provider "google" {}


# ==============================================================================
# CONDITIONAL ARCHITECTURE PATTERN: MEDALLION OR SINGLE DATASET
# ==============================================================================

# Jinja2 logic determines which architecture to provision based on the CLI prompt choice.
{% if cookiecutter.architecture_pattern == "medallion" %}

# ------------------------------------------------------------------------------
# MEDALLION ARCHITECTURE (RAW & SILVER)
# ------------------------------------------------------------------------------

# BRONZE (RAW) ZONE - Airflow Ingestion
module "{{ cookiecutter.domain_slug }}_landing_zone" {
  # Points to our central, standardized BigQuery module. Reusability ensures compliance.
  source = "../../../modules/data_platform_bigquery"

  # Standard resource tagging and naming conventions injected dynamically.
  project_id       = "{{ cookiecutter.gcp_project_id }}"
  dataset_id       = "{{ cookiecutter.environment }}_raw_{{ cookiecutter.domain_slug }}"
  cost_center      = "{{ cookiecutter.cost_center }}"
  data_sensitivity = "{{ cookiecutter.data_sensitivity }}"
  environment      = "{{ cookiecutter.environment }}"
  is_temp_sandbox  = {{ cookiecutter.is_temp_sandbox }}

  # ZERO-TRUST IAM (RAW): Only Airflow is allowed to WRITE (Editor) raw ingestion data here.
  dataset_editors = [
    "serviceAccount:{{ cookiecutter.airflow_worker_sa }}"
  ]
  # ZERO-TRUST IAM (RAW): dbt is only allowed to READ (Viewer) raw data. It cannot alter the source of truth.
  dataset_viewers = [
    "serviceAccount:{{ cookiecutter.dbt_worker_sa }}"
  ]
}

# SILVER ZONE - dbt Transformations
module "{{ cookiecutter.domain_slug }}_silver_zone" {
  source = "../../../modules/data_platform_bigquery"

  # Creates a distinct dataset for cleaned, conformed data.
  project_id       = "{{ cookiecutter.gcp_project_id }}"
  dataset_id       = "{{ cookiecutter.environment }}_silver_{{ cookiecutter.domain_slug }}"
  cost_center      = "{{ cookiecutter.cost_center }}"
  data_sensitivity = "{{ cookiecutter.data_sensitivity }}"
  environment      = "{{ cookiecutter.environment }}"
  is_temp_sandbox  = {{ cookiecutter.is_temp_sandbox }}

  # ZERO-TRUST IAM (SILVER): dbt is the sole owner/editor here. Airflow has no access to modify business-level data.
  dataset_editors = [
    "serviceAccount:{{ cookiecutter.dbt_worker_sa }}"
  ]
}

{% elif cookiecutter.architecture_pattern == "single_dataset" %}
# ------------------------------------------------------------------------------
# SINGLE LANDING ZONE (GENERIC DATASET)
# ------------------------------------------------------------------------------

module "{{ cookiecutter.domain_slug }}_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "{{ cookiecutter.gcp_project_id }}"
  # Omit the "raw" or "silver" label to create a flexible, general-purpose dataset.
  dataset_id       = "{{ cookiecutter.environment }}_{{ cookiecutter.domain_slug }}"
  cost_center      = "{{ cookiecutter.cost_center }}"
  data_sensitivity = "{{ cookiecutter.data_sensitivity }}"
  environment      = "{{ cookiecutter.environment }}"
  is_temp_sandbox  = {{ cookiecutter.is_temp_sandbox }}

  # COMBINED IAM: Because there are no distinct zones, both orchestration and transformation tools need edit access.
  dataset_editors = [
    "serviceAccount:{{ cookiecutter.airflow_worker_sa }}",
    "serviceAccount:{{ cookiecutter.dbt_worker_sa }}"
  ]
}
{% endif %}

# ==============================================================================
# CONDITIONAL REAL-TIME STREAMING INFRASTRUCTURE
# ==============================================================================

# Jinja2 logic evaluates if the engineer requested streaming capabilities during the CLI prompt.
{% if cookiecutter.include_realtime_streaming == "yes" %}

# REAL-TIME ZONE - Pub/Sub and Dataflow Streaming (Self-Service)
module "{{ cookiecutter.domain_slug }}_streaming_zone" {
  # Calls the central streaming module to automatically spin up topics and subscriptions.
  source = "../../../modules/data_platform_streaming"

  project_id  = "{{ cookiecutter.gcp_project_id }}"
  # Combines house prefix and domain slug (e.g., h2_bv_sales) to create an isolated, domain-specific streaming worker.
  domain_name = "{{cookiecutter.house_prefix}}_{{cookiecutter.domain_slug}}"
  environment = "{{ cookiecutter.environment }}"
  cost_center = "{{ cookiecutter.cost_center }}"
  topic_name  = "operational-events"
}
{% endif %}