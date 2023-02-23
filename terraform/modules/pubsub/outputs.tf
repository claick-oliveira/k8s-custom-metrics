// pubsub module
output "pubsub_topic" {
  value = google_pubsub_topic.example.name
}

output "pubsub_subscription" {
  value = google_pubsub_subscription.example.name
}
