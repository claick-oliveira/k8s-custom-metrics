// pubsub module
output "pubsub_topic" {
  description = "The Pub/Sub Topic"
  value       = google_pubsub_topic.example.name
}

output "pubsub_subscription" {
  description = "The Pub/Sub Subscription"
  value       = google_pubsub_subscription.example.name
}
