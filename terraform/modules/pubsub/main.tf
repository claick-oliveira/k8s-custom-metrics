// pubsub module
resource "google_pubsub_topic" "example" {
  name = "example-topic"
  message_retention_duration = "86600s"
}

resource "google_pubsub_subscription" "example" {
  name  = "example-subscription"
  topic = google_pubsub_topic.example.name

  labels = {
    subscription_id = "example-subscription"
  }

  # 20 minutes
  message_retention_duration = "1200s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
  retry_policy {
    minimum_backoff = "10s"
  }

  enable_message_ordering    = false
}
