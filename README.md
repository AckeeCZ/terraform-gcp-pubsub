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
      users : [
        "user:test@example.com",
      ]
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

 * allow_dlq_users_to_push_into_dlq_topic [boolean] - once enabled, users from dlq_users can also push to dlq topics
 * black_hole [boolean] -- add subscription with fairly short 600s retention
 * dlq [boolean] -- add dead letter queue to the topic
 * custom_dlq_postfix [string] -- change `dlq` subscription postfix from `-error` to `-${custom_dlq_postfix}`
 * custom_dlq_name [string] -- custom name for `dlq` topic & subscription
 * max_delivery_attempts [number] -- check [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription#max_delivery_attempts)
 * retry_policy [map(string)] -- check [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription#retry_policy)
 * enable_message_ordering [boolean] -- check [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription#enable_message_ordering)
 * custom_subscriptions [map(map(any))] -- accepts same arguments as topic, serves for custom subscription in case one is not enough
 * users [list(string)] -- list of users (with type, e.g: `serviceAccount:..., ...`), *beware* that any service account used as user has to be created before module usage
 * dlq_users [list(string)] -- list of users of DLQ subscription (with type, e.g: `serviceAccount:..., ...`), *beware* that any service account used as user has to be created before module usage
 * push_config [map(string)] -- check [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription#push_config)

Further examples are at [example](./example) folder.

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
| [google_pubsub_subscription_iam_member.internal_subscribers_to_source_subscriptions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription_iam_member) | resource |
| [google_pubsub_topic.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic.dlq](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.internal_publishers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.user_publishers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | GCP project name | `string` | n/a | yes |
| <a name="input_topics"></a> [topics](#input\_topics) | Map of maps of topics to be created with default subscription | `map` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dlq_subscriptions"></a> [dlq\_subscriptions](#output\_dlq\_subscriptions) | n/a |
| <a name="output_subscriptions"></a> [subscriptions](#output\_subscriptions) | n/a |
| <a name="output_topics"></a> [topics](#output\_topics) | n/a |
| <a name="output_topics_users"></a> [topics\_users](#output\_topics\_users) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
