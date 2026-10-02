variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "domain_name" {
  description = "The business domain (e.g., inventory, hr)"
  type        = string
}

variable "environment" {
  description = "The environment (dev or prod)"
  type        = string
}

variable "cost_center" {
  description = "Mandatory FinOps cost center tag"
  type        = string
}

variable "topic_name" {
  description = "The base name of the Pub/Sub topic"
  type        = string
}