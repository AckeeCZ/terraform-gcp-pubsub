output "topics" {
  value = google_pubsub_topic.default
}

output "subscriptions" {
  value = google_pubsub_subscription.default
}

output "dlq_topics" {
  value = google_pubsub_topic.dlq
}

output "dlq_subscriptions" {
  value = google_pubsub_subscription.error_queue
}

output "black_hole_subscriptions" {
  value = google_pubsub_subscription.black_hole
}
