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
    bucket = "gcp-terraform-tmp-tfstate-prasanna"

    # CRITICAL ZERO-TRUST ISOLATION: The prefix injects both the environment and house_prefix (e.g., dev/h1_gci_marketing).
    # This guarantees that a deployment failure in one brand mathematically cannot corrupt the state of another brand.
    prefix = "domains/dev/h2_bv_inventory"
  }
}

# Initializes the Google provider. Project and region are typically inherited from the environment or core setup.
provider "google" {}


# ==============================================================================
# CONDITIONAL ARCHITECTURE PATTERN: MEDALLION OR SINGLE DATASET
# ==============================================================================

# Jinja2 logic determines which architecture to provision based on the CLI prompt choice.

# ------------------------------------------------------------------------------
# SINGLE LANDING ZONE (GENERIC DATASET)
# ------------------------------------------------------------------------------

module "inventory_landing_zone" {
  source = "../../../modules/data_platform_bigquery"

  project_id       = "gcp-terraform-tmp"
  # Omit the "raw" or "silver" label to create a flexible, general-purpose dataset.
  dataset_id       = "dev_inventory"
  cost_center      = "bv_inventory_emea"
  data_sensitivity = "internal"
  environment      = "dev"
  is_temp_sandbox  = true

  # COMBINED IAM: Because there are no distinct zones, both orchestration and transformation tools need edit access.
  dataset_editors = [
    "serviceAccount:airflow-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com",
    "serviceAccount:dbt-dev-h2-bv-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}


# ==============================================================================
# CONDITIONAL REAL-TIME STREAMING INFRASTRUCTURE
# ==============================================================================

# Jinja2 logic evaluates if the engineer requested streaming capabilities during the CLI prompt.
