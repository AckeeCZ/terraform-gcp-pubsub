variable "project" {
}

module "pubsub" {
  source  = "../"
  project = var.project
  topics = {
    "topic-a" : {}
    "topic-b" : {
      dlq : true
    }
    "topic-c" : {
      black_hole : true
    }
    "topic-d" : {
      dlq : true
      custom_dlq_postfix : "dlq"
    }
    "topic-e" : {
      dlq : true
      custom_dlq_name : "averycustomthing-dlq"
    }
    "topic-f" : {
      custom_subscriptions : {
        topic-f-sub : {
          dlq : true
          custom_dlq_name : "averycustomthing-for-topic-f"
        }
        topic-f-sub2 : {
        }
      }
    }
  }
}
