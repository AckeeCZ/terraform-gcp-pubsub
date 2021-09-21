output "topics" {
  value = google_pubsub_topic.default
}

output "subscriptions" {
  value = google_pubsub_subscription.default
}
