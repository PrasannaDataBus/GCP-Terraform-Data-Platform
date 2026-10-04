# THE PLATFORM BLUEPRINT (CENTRAL ENGINE)
# Why we need this file: In a Data Mesh, we cannot let 50 different domain teams
# manually click around the GCP console to create datasets. It creates security
# risks and FinOps nightmares. This file is the "Central Engine". It forces every
# domain to follow strict governance, security, and cost rules automatically.

# ------------------------------------------------------------------------------
# 1. CORE INFRASTRUCTURE: THE LANDING ZONE
# Why we do this: This provisions the actual physical BigQuery dataset. We
# parameterize it so it can be reused for HR, Finance, Logistics, etc.
# ------------------------------------------------------------------------------
resource "google_bigquery_dataset" "domain_dataset" {
  project    = var.project_id
  dataset_id = var.dataset_id
  location   = var.location
  # Allows Terraform to cleanly destroy sandboxes without failing on remaining tables
  delete_contents_on_destroy = true

  # FINOPS GUARDRAIL: Automated lifecycle management.
  # If a domain requests a 'sandbox' environment, we force a 30-day (2,592,000,000 ms)
  # expiration on all tables to prevent abandoned data from inflating cloud bills.
  default_table_expiration_ms = var.is_temp_sandbox ? 2592000000 : null

  # GOVERNANCE-BY-DESIGN: Mandatory tagging.
  # FinOps uses 'cost_center' to charge back cloud spend to the right department.
  # SecOps uses 'data_sensitivity' to know if this dataset contains PII.
  labels = {
    managed_by       = "terraform-platform-engine"
    cost_center      = var.cost_center
    data_sensitivity = var.data_sensitivity
    environment      = var.environment
  }
}

# ------------------------------------------------------------------------------
# 2. AUTOMATED SECURITY: LEAST PRIVILEGE IAM (EDITORS)
# Why we do this: We never grant broad project-level permissions. We iterate
# through the exact list of service accounts (like Airflow or dbt) provided by
# the domain team and grant them 'Editor' access ONLY to this specific dataset.
# ------------------------------------------------------------------------------
resource "google_bigquery_dataset_iam_member" "editor_access" {
  for_each = toset(var.dataset_editors)

  project    = google_bigquery_dataset.domain_dataset.project
  dataset_id = google_bigquery_dataset.domain_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = each.value
}

# ------------------------------------------------------------------------------
# 3. AUTOMATED SECURITY: LEAST PRIVILEGE IAM (VIEWERS)
# Why we do this: Downstream BI tools (like PowerBI or Looker) should never
# have write access. This block ensures read-only isolation.
# ------------------------------------------------------------------------------
resource "google_bigquery_dataset_iam_member" "viewer_access" {
  for_each = toset(var.dataset_viewers)

  project    = google_bigquery_dataset.domain_dataset.project
  dataset_id = google_bigquery_dataset.domain_dataset.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = each.value
}

# ------------------------------------------------------------------------------
# 4. OBSERVABILITY-AS-A-SERVICE: THE ERROR LOG SINK
# Why we do this: Proactive Incident Management. Instead of waiting for a domain
# team to report a broken pipeline, this automatically captures all dataset failures.
# ------------------------------------------------------------------------------
resource "google_logging_project_sink" "domain_error_sink" {
  # We dynamically name the sink so we know exactly which dataset generated the error.
  name = "${var.dataset_id}-bq-error-sink-${var.environment}"

  # For this demo, we route to the default project logging bucket to stay within
  # the Free Tier. (In production, we would route this to a central SecOps BigQuery dataset).
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/_Default"

  # FINOPS FILTER: This is the magic line. BigQuery generates millions of 'INFO' logs
  # for successful queries. Storing them costs thousands of dollars. We aggressively
  # filter for 'ERROR' only. We get 100% of the operational visibility for $0.
  filter = "resource.type=\"bigquery_resource\" AND severity >= ERROR"

  # Creates a dedicated GCP service account specifically for this sink to ensure
  # secure log routing across project boundaries.
  unique_writer_identity = true
}