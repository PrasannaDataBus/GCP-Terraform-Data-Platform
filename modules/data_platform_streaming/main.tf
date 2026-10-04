# OBSERVABILITY PATTERN: THE DEAD LETTER QUEUE (DLQ)
# Why we do this: If a subscriber (like Dataflow) fails to process a message
# (e.g., due to a schema mismatch or temporary network outage), we do not want
# the message to be deleted and lost forever. We route it here so engineers
# can inspect the failure, fix the bug, and replay the data.

resource "google_pubsub_topic" "dlq_topic" {
  # We append '-dlq-' to clearly distinguish this topic from the main production flow.
  name    = "${var.domain_name}-${var.topic_name}-dlq-${var.environment}"
  project = var.project_id

  # FinOps & Governance: Labels are crucial for observability in cloud billing.
  # This allows the FinOps team to track exactly how much the DLQ costs per domain.
  labels = {
    environment = var.environment
    cost_center = var.cost_center
    domain      = var.domain_name
    type        = "streaming-dlq"
  }
}

# CORE INFRASTRUCTURE: THE MAIN STREAMING TOPIC
# Why we do this: This is the primary entry point where upstream applications
# (e.g., website trackers, backend services) publish their real-time data.

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

# DATA ROUTING: THE SUBSCRIPTION
# Why we do this: Topics only receive data; Subscriptions are required to actually
# pull or push that data to a consumer. This binds the main topic to the consumers.

resource "google_pubsub_subscription" "main_subscription" {
  name    = "${var.domain_name}-${var.topic_name}-sub-${var.environment}"
  project = var.project_id
  # We link this subscription directly to the main topic created above.
  topic   = google_pubsub_topic.main_topic.name

  # Why we do this: This is the automated observability trigger. If Dataflow pulls
  # a message and crashes, Pub/Sub will retry. If it fails 5 times, Pub/Sub stops
  # retrying and forwards the poisoned message to the DLQ. This prevents "head-of-line
  # blocking" where one bad message halts the entire pipeline.

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq_topic.id
    max_delivery_attempts = 5
  }

  labels = {
    environment = var.environment
    cost_center = var.cost_center
  }
}

# SECURITY & GOVERNANCE: LEAST PRIVILEGE SERVICE ACCOUNT
# Why we do this: Instead of using a highly privileged default compute account,
# we create a dedicated Service Account purely for this specific streaming job.
# This strictly limits the blast radius if the account credentials are compromised.

resource "google_service_account" "streaming_worker" {
  # GCP limits account IDs to 30 characters and requires specific regex formats.
  # We use the 'replace' function to dynamically sanitize the domain name (e.g.,
  # turning "hr_global" into "hr-global") to prevent deployment crashes.
  account_id   = "sa-${replace(var.domain_name, "_", "-")}-str-${var.environment}"
  display_name = "Dataflow Streaming Worker for ${var.domain_name}"
  project      = var.project_id
}