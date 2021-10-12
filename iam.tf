data "google_project" "project" {
  project_id = var.project
}

resource "google_pubsub_subscription_iam_member" "internal_subscribers_to_original_queues" {
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
