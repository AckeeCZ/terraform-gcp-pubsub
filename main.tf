locals {
  # TODO: check if foreach data type is still strictly using keys as string to rewrite
  subscriptions = toset(flatten([
    for q in google_pubsub_topic.default :
    [
      for j in keys(lookup(var.topics[q.name], "custom_subscriptions", { "${q.name}" : {} })) :
      "${q.name}␟${j}" if !lookup(var.topics[q.name], "black_hole", false) && !lookup(var.topics[q.name], "no_subscription", false)
    ]
  ]))
  _dlq_subscriptions = [
    for q in google_pubsub_topic.default :
    {
      for k, v in lookup(var.topics[q.name], "custom_subscriptions",
        {
          "${q.name}" : {
            dlq : lookup(var.topics[q.name], "dlq", false)
            allow_dlq_users_to_push_into_dlq_topic : lookup(var.topics[q.name], "allow_dlq_users_to_push_into_dlq_topic", false)
            custom_dlq_name : lookup(var.topics[q.name], "custom_dlq_name", "${q.name}-${lookup(var.topics[q.name], "custom_dlq_postfix", "error")}")
            dlq_users : lookup(var.topics[q.name], "dlq_users", [])
          }
      }) :
      k => {
        dlq : lookup(v, "dlq", false),
        allow_dlq_users_to_push_into_dlq_topic : lookup(v, "allow_dlq_users_to_push_into_dlq_topic", false),
        custom_dlq_name : lookup(v, "custom_dlq_name", "${k}-${lookup(v, "custom_dlq_postfix", "error")}"),
        dlq_users : lookup(v, "dlq_users", [])
      }
    }
  ]
  dlq_subscriptions = toset(flatten([
    for i in local._dlq_subscriptions :
    [
      for k, v in i :
      "${k}␟${v["custom_dlq_name"]}" if v["dlq"] == true
    ]
  ]))
  _dlq_subscriptions_users = toset(flatten([
    for i in local._dlq_subscriptions :
    flatten([
      for k, v in i :
      [
        for u in v["dlq_users"] :
        "${k}␟${v["custom_dlq_name"]}␟${u}" if v["dlq"] == true
      ]
    ])
  ]))
  _dlq_publishers_users = toset(flatten([
    for i in local._dlq_subscriptions :
    flatten([
      for k, v in i :
      [
        for u in v["dlq_users"] :
        "${k}␟${v["custom_dlq_name"]}␟${u}" if v["dlq"] == true && v["allow_dlq_users_to_push_into_dlq_topic"] == true
      ]
    ])
  ]))
}

resource "google_pubsub_topic" "default" {
  for_each = toset(keys(var.topics))
  name     = each.value
  dynamic "schema_settings" {
    for_each = lookup(var.topics[each.value], "schema_definition", {}) != {} ? [1] : []
    content {
      schema   = google_pubsub_schema.default[each.key].id
      encoding = lookup(var.topics[each.value], "schema_encoding", "JSON")
    }
  }
  depends_on = [google_pubsub_schema.default]
}

resource "google_pubsub_subscription" "default" {
  for_each = toset(local.subscriptions)

  topic = split("␟", each.value)[0]
  name  = split("␟", each.value)[1]

  dynamic "push_config" {
    for_each = [for i in [lookup(
      lookup(
        lookup(
          var.topics[split("␟", each.value)[0]],
          "custom_subscriptions",
          {}
        ),
        split("␟", each.value)[1],
        {
          push_config : lookup(
            var.topics[split("␟", each.value)[0]],
            "push_config",
            {}
          )
        }
      ),
      "push_config",
      {}
    )] : i if i != {}]
    content {
      dynamic "oidc_token" {
        for_each = compact([lookup(push_config.value, "service_account_email", "")])
        content {
          service_account_email = oidc_token.value
        }
      }
      push_endpoint = push_config.value["push_endpoint"]
    }
  }

  ack_deadline_seconds = lookup(
    lookup(
      lookup(
        var.topics[split("␟", each.value)[0]],
        "custom_subscriptions",
        {}
      ),
      split("␟", each.value)[1],
      {
        ack_deadline_seconds : lookup(
          var.topics[split("␟", each.value)[0]],
          "ack_deadline_seconds",
          60
        )
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
      i if split("␟", i)[0] == split("␟", each.value)[1]
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
            max_delivery_attempts : lookup(
              var.topics[split("␟", each.value)[0]],
              "max_delivery_attempts",
              5
            )
          }
        ),
        "max_delivery_attempts",
        5
      )
    }
  }

  dynamic "bigquery_config" {
    for_each = [for i in [lookup(
      lookup(
        lookup(
          var.topics[split("␟", each.value)[0]],
          "custom_subscriptions",
          {}
        ),
        split("␟", each.value)[1],
        {
          bigquery_config : lookup(
            var.topics[split("␟", each.value)[0]],
            "bigquery_config",
            {}
          )
        }
      ),
      "bigquery_config",
      {}
    )] : i if i != {}]
    content {
      table               = bigquery_config.value["table"]
      drop_unknown_fields = lookup(bigquery_config.value, "drop_unknown_fields", null)
      use_topic_schema    = lookup(bigquery_config.value, "use_topic_schema", null)
      write_metadata      = lookup(bigquery_config.value, "write_metadata", null)
    }
  }

  dynamic "retry_policy" {
    for_each = [for i in [lookup(
      lookup(
        lookup(
          var.topics[split("␟", each.value)[0]],
          "custom_subscriptions",
          {}
        ),
        split("␟", each.value)[1],
        {
          retry_policy : lookup(
            var.topics[split("␟", each.value)[0]],
            "retry_policy",
            {}
          )
        }
      ),
      "retry_policy",
      {}
    )] : i if i != {}]
    content {
      minimum_backoff = retry_policy.value["minimum_backoff"]
      maximum_backoff = retry_policy.value["maximum_backoff"]
    }
  }
  enable_message_ordering = lookup(
    lookup(
      lookup(
        var.topics[split("␟", each.value)[0]],
        "custom_subscriptions",
        {}
      ),
      split("␟", each.value)[1],
      {
        enable_message_ordering : lookup(
          var.topics[split("␟", each.value)[0]],
          "enable_message_ordering",
          false
        )
      }
    ),
    "enable_message_ordering",
    false
  )
  message_retention_duration = lookup(
    lookup(
      lookup(
        var.topics[split("␟", each.value)[0]],
        "custom_subscriptions",
        {}
      ),
      split("␟", each.value)[1],
      {
        message_retention_duration : lookup(
          var.topics[split("␟", each.value)[0]],
          "message_retention_duration",
          null
        )
      }
    ),
    "message_retention_duration",
    null
  )
  depends_on = [google_pubsub_topic.default, google_bigquery_table_iam_member.bigquery_push_permissions]
}

resource "google_pubsub_subscription" "black_hole" {
  for_each = toset([for q in google_pubsub_topic.default : q.name if lookup(var.topics[q.name], "black_hole", false)])
  name     = "${each.value}-black-hole"
  topic    = each.value
  expiration_policy {
    ttl = ""
  }
  message_retention_duration = "600s"
  depends_on                 = [google_pubsub_topic.default]
}

resource "google_pubsub_topic" "dlq" {
  for_each = toset([for i in local.dlq_subscriptions : split("␟", i)[1]])
  name     = each.value
}

resource "google_pubsub_subscription" "error_queue" {
  for_each = toset([for i in local.dlq_subscriptions : split("␟", i)[1]])
  topic    = each.value
  name     = each.value
  expiration_policy {
    ttl = ""
  }
  depends_on = [google_pubsub_topic.dlq]
}
