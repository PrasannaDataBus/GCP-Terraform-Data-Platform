# Infrastructure Engine

resource "google_bigquery_dataset" "domain_dataset" {
  project                    = var.project_id
  dataset_id                 = var.dataset_id
  location                   = var.location
  delete_contents_on_destroy = true

  # FINOPS GUARDRAIL: Auto-delete tables after 30 days if this is a sandbox
  default_table_expiration_ms = var.is_temp_sandbox ? 2592000000 : null

  # GOVERNANCE BY DESIGN: Standardized tagging across the enterprise
  labels = {
    managed_by       = "terraform-platform-engine"
    cost_center      = var.cost_center
    data_sensitivity = var.data_sensitivity
    environment      = var.is_temp_sandbox ? "sandbox" : "production"
  }
}

# AUTOMATED IAM SECUIRTY: Dynamically grants access only to approved users
resource "google_bigquery_dataset_iam_member" "editor_access" {
  for_each = toset(var.dataset_editors)

  project    = google_bigquery_dataset.domain_dataset.project
  dataset_id = google_bigquery_dataset.domain_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = each.value
}

