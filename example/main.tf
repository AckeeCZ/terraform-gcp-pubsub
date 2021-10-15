variable "project" {
}

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
    "topic-d" : {
      black_hole : true
    }
    "topic-a" : {
      minimum_backoff : "60s"
      maximum_backoff : "120s"
    }
    "topic-b" : {
      dlq : true
      custom_dlq_name : "abc"
      users : [
        "serviceAccount:${google_service_account.service_a.email}",
      ]
    },
    "topic-f" : {
      custom_subscriptions : {
        f-sub : {
          dlq : true
          custom_dlq_name : "averycustomthing-for-topic-f"
          max_delivery_attempts : 100
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
