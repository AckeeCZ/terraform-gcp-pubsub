resource "google_pubsub_schema" "default" {
  for_each   = { for k, v in var.topics : k => v if lookup(v, "schema_definition", {}) != {} }
  name       = each.key
  type       = lookup(each.value, "schema_type", "AVRO")
  definition = each.value["schema_definition"]
}
