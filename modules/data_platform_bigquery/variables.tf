## Enforcing Governance

variable "project_id" {
  description = "The GCP project ID for the domain."
  type        = string
}

variable "dataset_id" {
  description = "The name of the BigQuery dataset."
  type        = string
}

variable "location" {
  description = "Deployment region. Forced to EU for GDPR compliance."
  type        = string
  default     = "EU"
}

variable "cost_center" {
  description = "FinOps requirement: Which House/Domain pays for this compute?"
  type        = string
}

variable "data_sensitivity" {
  description = "Governance requirement: Classification of data."
  type        = string

  # PLATFORM GUARDRAIL: Terraform will fail if the domain engineer types a wrong value
  validation {
    condition     = contains(["public", "internal", "pii", "financial", "confidential"], var.data_sensitivity)
    error_message = "Data sensitivity must be exactly: public, internal, pii, or financial."
  }
}

variable "is_temp_sandbox" {
  description = "If true, enforces a 30-day deletion policy on all tables to save costs."
  type        = bool
  default     = false
}

variable "dataset_editors" {
  description = "List of IAM service accounts or groups that need Editor access."
  type        = list(string)
  default     = []
}

variable "dataset_viewers" {
  type        = list(string)
  description = "List of IAM members granted roles/bigquery.dataViewer"
  default     = []
}

variable "environment" {
  type        = string
  description = "Target environment (e.g. dev, staging, production)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}