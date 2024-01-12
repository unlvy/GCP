terraform {
  required_version = ">= 1.6"

  required_providers {
	google = ">= 5.10"
  }
}

provider "google" {
  project = var.project_id
}

# CLOUD RUN
resource "google_cloud_run_service" "uploader" {
  name = var.app_name
  location = var.location
  template {
    spec {
      containers {
        image = var.uploader_image
        env {
          name = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name = "BUCKET_NAME"
          value = var.bucket_name
        }
        env {
          name = "PUBSUB_TOPIC_NAME"
          value = var.pubsub_topic_name
        }
      }
    }
  }
  depends_on = [
    google_storage_bucket.static,
    google_pubsub_subscription.subscription
  ]
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.uploader.location
  project     = google_cloud_run_service.uploader.project
  service     = google_cloud_run_service.uploader.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

# CLOUD STORAGE
resource "google_storage_bucket" "static" {
  name = var.bucket_name
  location = var.location
  force_destroy = true
  uniform_bucket_level_access = true
}

# PUBSUB
resource "google_pubsub_topic" "topic" {
  name = var.pubsub_topic_name
}

resource "google_pubsub_subscription" "subscription" {
  name = var.pubsub_subscription_name
  topic = google_pubsub_topic.topic.name
  ack_deadline_seconds = 30
}

# CLOUD FUNCTIONS
resource "google_storage_bucket" "cloud_function_bucket" {
  name = var.cloud_function_bucket_name
  location = var.location
}

resource "google_storage_bucket_object" "archive" {
  name   = var.cloud_function_object_name
  bucket = google_storage_bucket.cloud_function_bucket.name
  source = "../dist/cloud_function.zip"
}

resource "google_cloudfunctions_function" "function" {
  name = "email-notifier"
  region = var.location
  runtime = "nodejs18"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.topic.name
  }

  source_archive_bucket = google_storage_bucket.cloud_function_bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  entry_point = "email_notifier"

  depends_on = [
    google_storage_bucket_object.archive,
    google_pubsub_topic.topic
  ]
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project = google_cloudfunctions_function.function.project
  region  = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}