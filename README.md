# PubSub Terraform Module

This module help us to keep our configuration standard. We had issues with forgetting correct SA permissions on DLQ.
Having everything in a module can keep the issue away.

## Usage

Everything could be defined in `topics` variable:

```
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
      custom_dlq_postfix: "-dlq"
    }
  }
}
```

`topics` map items can have define following keys:

 * black_hole [boolean] -- add subscription with fairly short 600s retention
 * dlq [boolean] -- add dead letter queue to the topic
 * custom_dlq_postfix [string] -- change `dlq` subscription postfix from `-error` to `-${custom_dlq_postfix}`


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_pubsub_subscription.black_hole](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_subscription.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_subscription.error_queue](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_subscription_iam_member.internal_subscribers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription_iam_member) | resource |
| [google_pubsub_subscription_iam_member.internal_subscribers_to_original_queues](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription_iam_member) | resource |
| [google_pubsub_topic.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic.dlq](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.internal_publishers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | GCP project name | `string` | n/a | yes |
| <a name="input_topics"></a> [topics](#input\_topics) | Map of maps of topics to be created with default subscription | `map` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subscriptions"></a> [subscriptions](#output\_subscriptions) | n/a |
| <a name="output_topics"></a> [topics](#output\_topics) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
