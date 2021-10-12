locals {
  # TODO: check if foreach data type is still scricly using maps with string and rewrite
  subscriptions = toset(flatten([
    for q in google_pubsub_topic.default :
    [
      for j in keys(lookup(var.topics[q.name], "custom_subscriptions", { "${q.name}" : {} })) :
      "${q.name}␟${j}" if !lookup(var.topics[q.name], "black_hole", false)
    ]
  ]))
  _dlq_subscriptions = [
    for q in google_pubsub_topic.default :
    {
      for k, v in lookup(var.topics[q.name], "custom_subscriptions", { "${q.name}" : {
        "dlq" : lookup(var.topics[q.name], "dlq", false)
        "dlq_name" : lookup(var.topics[q.name], "custom_dlq_name", "${q.name}-${lookup(var.topics[q.name], "custom_dlq_postfix", "error")}")
      } }) :
      k => {
        dlq : lookup(v, "dlq", false),
        dlq_name : lookup(v, "dlq_name", "${k}-${lookup(v, "custom_dlq_postfix", "error")}"),
      }
    }
  ]
  dlq_subscriptions = toset(flatten([
    for i in local._dlq_subscriptions :
    [
      for k, v in i :
      "${k}␟${v["dlq_name"]}" if v["dlq"] == true
    ]
  ]))
}

resource "google_pubsub_topic" "default" {
  for_each = toset(keys(var.topics))
  name     = each.value
}

resource "google_pubsub_subscription" "default" {
  for_each = toset(local.subscriptions)

  topic = split("␟", each.value)[0]
  name  = split("␟", each.value)[1]

  ack_deadline_seconds = lookup(
    lookup(
      lookup(
        var.topics[split("␟", each.value)[0]],
        "custom_subscriptions",
        {}
      ),
      split("␟", each.value)[1],
      {
        ack_deadline_seconds : 60
      }
    ),
    "ack_deadline_seconds",
    60
  )

  expiration_policy {
    ttl = ""
  }

  dynamic "dead_letter_policy" {
    for_each = [
      for i in local.dlq_subscriptions :
      # TODO: check if could be refactored in the future
      i if substr(i, 0, length("${split("␟", each.value)[0]}␟")) == "${split("␟", each.value)[0]}␟"
    ]
    content {
      dead_letter_topic = google_pubsub_topic.dlq[split("␟", dead_letter_policy.value)[1]].id
      max_delivery_attempts = lookup(
        lookup(
          lookup(
            var.topics[split("␟", each.value)[0]],
            "custom_subscriptions",
            {}
          ),
          split("␟", each.value)[1],
          {
            max_delivery_attempts : 5
          }
        ),
        "max_delivery_attempts",
        5
      )
    }
  }

  retry_policy {
    minimum_backoff = lookup(
      lookup(
        lookup(
          var.topics[split("␟", each.value)[0]],
          "custom_subscriptions",
          {}
        ),
        split("␟", each.value)[1],
        {
          minimum_backoff : "10s"
        }
      ),
      "minimum_backoff",
      "10s"
    )
    maximum_backoff = lookup(
      lookup(
        lookup(
          var.topics[split("␟", each.value)[0]],
          "custom_subscriptions",
          {}
        ),
        split("␟", each.value)[1],
        {
          maximum_backoff : "300s"
        }
      ),
      "maximum_backoff",
      "300s"
    )
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
  for_each = toset([for i in local.dlq_subscriptions : split("␟", i)[1]])
  name     = each.value
}

resource "google_pubsub_subscription" "error_queue" {
  for_each = toset([for i in local.dlq_subscriptions : split("␟", i)[1]])
  topic    = each.value
  name     = each.value
}
