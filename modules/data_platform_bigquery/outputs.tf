# The Return Interface

output "dataset_id" {
  description = "The ID of the created BigQuery dataset."
  value       = google_bigquery_dataset.domain_dataset.dataset_id
}

output "dataset_self_link" {
  description = "The URI of the created dataset for downstream Airflow/dbt tools."
  value       = google_bigquery_dataset.domain_dataset.self_link
}
