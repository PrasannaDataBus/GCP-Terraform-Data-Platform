provider "google" {
  # Initializes GCP connection
}

module "gci_marketing_landing_zone" {
  source = "../../modules/data_platform_bigquery"

  # REPLACE WITH YOUR ACTUAL GCP PROJECT ID
  project_id       = "gcp-terraform-tmp"
  dataset_id       = "raw_gci_marketing_prod"

  # FinOps & Governance inputs required by your platform rules
  cost_center      = "gci_marketing_emea"
  data_sensitivity = "pii"
  is_temp_sandbox  = false

  # Automatically grants Airflow or dbt service accounts access
  dataset_editors  = [
    "serviceAccount:airflow-platform-worker@gcp-terraform-tmp.iam.gserviceaccount.com"
  ]
}