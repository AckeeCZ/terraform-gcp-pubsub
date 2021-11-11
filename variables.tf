variable "topics" {
  default     = {}
  description = "Map of maps of topics to be created with default subscription"
}

variable "project" {
  description = "GCP project ID"
  type        = string
}
