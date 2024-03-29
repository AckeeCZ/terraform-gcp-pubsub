data "google_project" "project" {
  project_id = var.project
}

locals {
  topics_users = {
    for q in google_pubsub_topic.default :
    "${q.name}" => lookup(var.topics[q.name], "users", [])
  }
  topics_users_bindings_to_list = flatten(
    [
      for k, v in local.topics_users :
      [
        for j in v : "${k}␟${j}"
      ]
    ]
  )

  _subscriptions_users = flatten([
    for q in google_pubsub_topic.default :
    [
      for j in keys(lookup(var.topics[q.name], "custom_subscriptions", { "${q.name}" : {} })) :
      {
        "${q.name}␟${j}" : lookup(
          lookup(
            lookup(
              var.topics[q.name],
              "custom_subscriptions",
              {}
            ),
            j,
            var.topics[q.name]
          ),
          "users",
          []
        )
      } if !lookup(var.topics[q.name], "black_hole", false) && !lookup(var.topics[q.name], "no_subscription", false)
    ]
  ])
  _subscriptions_users_merge = merge(local._subscriptions_users...)
  subscriptions_users = toset(flatten([
    for i in keys(local._subscriptions_users_merge) :
    [
      for j in local._subscriptions_users_merge[i] : "${i}␟${j}"
    ]
  ]))
}

resource "google_pubsub_subscription_iam_member" "internal_subscribers_to_source_subscriptions" {
  for_each     = toset([for i in google_pubsub_subscription.default : i.name])
  subscription = each.value
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "internal_publishers" {
  for_each = toset([for i in google_pubsub_topic.dlq : i.name])
  topic    = each.value
  role     = "roles/pubsub.publisher"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "internal_subscribers" {
  for_each     = toset([for i in google_pubsub_subscription.error_queue : i.name])
  subscription = each.key
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "user_publishers" {
  for_each = toset(local.topics_users_bindings_to_list)
  topic    = split("␟", each.value)[0]
  role     = "roles/pubsub.publisher"
  member   = split("␟", each.value)[1]
}

resource "google_pubsub_subscription_iam_member" "user_subscribers" {
  for_each     = toset(local.subscriptions_users)
  subscription = split("␟", each.value)[1]
  role         = "roles/pubsub.subscriber"
  member       = split("␟", each.value)[2]
  depends_on   = [google_pubsub_subscription.default]
}

resource "google_pubsub_topic_iam_member" "dlq_user_publishers" {
  for_each = toset(local._dlq_publishers_users)
  topic    = split("␟", each.value)[1]
  role     = "roles/pubsub.publisher"
  member   = split("␟", each.value)[2]
}

resource "google_pubsub_subscription_iam_member" "dlq_user_subscribers" {
  for_each     = toset(local._dlq_subscriptions_users)
  subscription = split("␟", each.value)[1]
  role         = "roles/pubsub.subscriber"
  member       = split("␟", each.value)[2]
  depends_on   = [google_pubsub_subscription.error_queue]
}

resource "google_bigquery_table_iam_member" "bigquery_push_permissions" {
  for_each = toset(flatten([for i in local.subscriptions : [for j in [lookup(
    lookup(
      lookup(
        var.topics[split("␟", i)[0]],
        "custom_subscriptions",
        {}
      ),
      split("␟", i)[1],
      {
        bigquery_config : lookup(
          var.topics[split("␟", i)[0]],
          "bigquery_config",
          {}
        )
      }
    ),
    "bigquery_config",
    {}
  )] : j["table"] if j != {}]]))
  project    = split(".", each.value)[0]
  dataset_id = split(".", each.value)[1]
  table_id   = split(".", each.value)[2]
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
