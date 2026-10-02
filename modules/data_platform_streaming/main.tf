# The Dead Letter Queue (DLQ) Topic - Enforcing Observability
resource "google_pubsub_topic" "dlq_topic" {
  name    = "${var.domain_name}-${var.topic_name}-dlq-${var.environment}"
  project = var.project_id

  labels = {
    environment = var.environment
    cost_center = var.cost_center
    domain      = var.domain_name
    type        = "streaming-dlq"
  }
}

# The Main Streaming Topic
resource "google_pubsub_topic" "main_topic" {
  name    = "${var.domain_name}-${var.topic_name}-${var.environment}"
  project = var.project_id

  labels = {
    environment = var.environment
    cost_center = var.cost_center
    domain      = var.domain_name
    type        = "streaming-main"
  }
}

# The Subscription linking the Main Topic to the DLQ
resource "google_pubsub_subscription" "main_subscription" {
  name    = "${var.domain_name}-${var.topic_name}-sub-${var.environment}"
  project = var.project_id
  topic   = google_pubsub_topic.main_topic.name

  # Route messages to DLQ after 5 failed delivery attempts
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq_topic.id
    max_delivery_attempts = 5
  }

  labels = {
    environment = var.environment
    cost_center = var.cost_center
  }
}

# Service Account for Streaming Compute (Dataflow)
resource "google_service_account" "streaming_worker" {
  # Shortened 'stream' to 'str' to stay safely under GCP's 30-character limit
  # Replaces underscores with hyphens to satisfy GCP regex limits
  account_id   = "sa-${replace(var.domain_name, "_", "-")}-str-${var.environment}"
  display_name = "Dataflow Streaming Worker for ${var.domain_name}"
  project      = var.project_id
}