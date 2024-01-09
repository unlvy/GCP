variable "project_id" {
    type = string
    default = "gcp-proj-410512"
}

variable "bucket_name" {
    type = string
    default = "gcp-proj-static-bucket"
}

variable "app_name" {
    type = string
    default = "gcp-proj-app-uploader"
}

variable "location" {
    type = string
    default = "us-central1"
}

variable "uploader_image" {
    type = string
    default = "us-central1-docker.pkg.dev/gcp-proj-410512/app-uploader/uploader"
}

variable "pubsub_topic_name" {
    type = string 
    default = "uploader-pubsub-topic"
}

variable "pubsub_subscription_name" {
    type = string
    default = "uploader-pubsub-subscription"
}

variable "cloud_function_bucket_name" {
    type = string
    default = "gcp-bucket-email-notifier-function"
}

variable "cloud_function_object_name" {
    type = string
    default = "gcp-archive-email-notifier-function"
}