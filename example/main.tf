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
      custom_dlq_postfix : "-dlq"
    }
  }
}
