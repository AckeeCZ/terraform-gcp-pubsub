variable "project" {
}

// BEWARE
// Apply google_service_account first:
// terraform apply -target='google_service_account.service_a' -target='google_service_account.service_b'
// Otherwise terraform reports following error:
//╷
//│ Error: Invalid for_each argument
//│
//│   on .terraform/modules/pubsub/iam.tf line 71, in resource "google_pubsub_topic_iam_member" "user_publishers":
//│   71:   for_each = toset(local.topics_users_bindings_to_list)
//│     ├────────────────
//│     │ local.topics_users_bindings_to_list is tuple with 1 element
//│
//│ The "for_each" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many
//│ instances will be created. To work around this, use the -target argument to first apply only the resources that the for_each
//│ depends on.
//╵
//╷
//│ Error: Invalid for_each argument
//│
//│   on .terraform/modules/pubsub/iam.tf line 78, in resource "google_pubsub_subscription_iam_member" "user_subscribers":
//│   78:   for_each     = toset(local.subscriptions_users)
//│     ├────────────────
//│     │ local.subscriptions_users is set of string with 4 elements
//│
//│ The "for_each" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many
//│ instances will be created. To work around this, use the -target argument to first apply only the resources that the for_each
//│ depends on.
//╵


resource "google_service_account" "service_a" {
  account_id   = "service-a"
  display_name = "service-a"
}

resource "google_service_account" "service_b" {
  account_id   = "service-b"
  display_name = "service-b"
}

module "pubsub" {
  source  = "../"
  project = var.project
  topics = {
    "topic-a" : {
      minimum_backoff : "60s"
      maximum_backoff : "120s"
    },
    "topic-b" : {
      dlq : true
      custom_dlq_name : "abc"
      users : [
        "serviceAccount:${google_service_account.service_a.email}",
      ]
    },
    "topic-d" : {
      black_hole : true
    },
    "topic-e" : {
      dlq : true
      custom_dlq_name : "dlq"
    },
    "topic-f" : {
      custom_subscriptions : {
        f-sub : {
          dlq : true
          custom_dlq_name : "averycustomthing-for-topic-f"
          max_delivery_attempts : 100
          dlq_users : [
            "serviceAccount:${google_service_account.service_a.email}",
            "serviceAccount:${google_service_account.service_b.email}",
          ]
        },
        f-sub1 : {
          users : [
            "serviceAccount:${google_service_account.service_b.email}",
          ]
        },
        f-sub2 : {
          users : [
            "serviceAccount:${google_service_account.service_a.email}",
            "serviceAccount:${google_service_account.service_b.email}",
          ]
        }
      }
    }
  }
}
