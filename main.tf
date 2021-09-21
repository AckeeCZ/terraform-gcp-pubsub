resource "google_pubsub_topic" "default" {
  for_each = toset(keys(var.topics))
  name     = each.value
}

resource "google_pubsub_subscription" "default" {
  for_each = toset([for q in google_pubsub_topic.default : q.name if !lookup(var.topics[q.name], "black_hole", false)])

  name                 = each.value
  topic                = each.value
  ack_deadline_seconds = lookup(var.topics[each.value], "ack_deadline_seconds", 60)

  expiration_policy {
    ttl = ""
  }

  dynamic "dead_letter_policy" {
    for_each = lookup(var.topics[each.value], "dlq", false) ? [1] : []
    content {
      dead_letter_topic     = google_pubsub_topic.dlq[each.value].id
      max_delivery_attempts = lookup(var.topics[each.value], "max_delivery_attempts", 5)
    }
  }

  retry_policy {
    minimum_backoff = lookup(var.topics[each.value], "minimum_backoff", "10s")
    maximum_backoff = lookup(var.topics[each.value], "maximum_backoff", "300s")
  }

  depends_on = [google_pubsub_topic.default]
}

resource "google_pubsub_subscription" "black_hole" {
  for_each = toset([for q in google_pubsub_topic.default : q.name if lookup(var.topics[q.name], "black_hole", false)])

  name  = "${each.value}-black-hole"
  topic = each.value

  expiration_policy {
    ttl = ""
  }

  message_retention_duration = "600s"
}

resource "google_pubsub_topic" "dlq" {
  for_each = toset([for q in google_pubsub_topic.default : q.name if lookup(var.topics[q.name], "dlq", false)])
  name     = "${each.value}-${lookup(var.topics[each.value], "custom_dlq_postfix", "error")}"
}

resource "google_pubsub_subscription" "error_queue" {
  for_each = toset([for q in google_pubsub_topic.default : q.name if lookup(var.topics[q.name], "dlq", false)])
  topic    = "${each.value}-${lookup(var.topics[each.value], "custom_dlq_postfix", "error")}"
  name     = "${each.value}-${lookup(var.topics[each.value], "custom_dlq_postfix", "error")}"

  depends_on = [google_pubsub_topic.dlq]
}
