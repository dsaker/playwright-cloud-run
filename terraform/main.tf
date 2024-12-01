# resource "google_artifact_registry_repository" "playwright-python" {
#   location      = var.region
#   repository_id = var.repository_id
#   description   = "example docker repository for python playwright test scripts"
#   format        = "DOCKER"
#
# }
#
# locals {
#   l = google_artifact_registry_repository.playwright-python.location
#   p = google_artifact_registry_repository.playwright-python.project
#   r = google_artifact_registry_repository.playwright-python.repository_id
#   image = "${local.l}-docker.pkg.dev/${local.p}/${local.r}/${var.image_name}:${var.image_version}"
# }

# create local data to store registry info for image name
locals {
  l = data.google_artifact_registry_repository.playwright-repo.location
  p = data.google_artifact_registry_repository.playwright-repo.project
  r = data.google_artifact_registry_repository.playwright-repo.repository_id
  image = "${local.l}-docker.pkg.dev/${local.p}/${local.r}/${var.image_name}:${var.image_version}"
}

data "google_artifact_registry_repository" "playwright-repo" {
  location      = var.region
  repository_id = var.repository_id
}

# cloud run job to run container
resource "google_cloud_run_v2_job" "playwright" {
  name     = "playwright-cloudrun-job"
  location = var.region
  deletion_protection = false

  template {
    template {
      containers {
        image = local.image
      }
    }
  }
}

# service account to run cloud run job
resource "google_service_account" "sa-name" {
  account_id = "cloud-run-invoker"
}

resource "google_project_iam_member" "cloud-run-builder" {
  project = var.project_id
  role    = "roles/run.builder"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}

resource "google_project_iam_member" "cloud-run-invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}

# cloud scheduler to schedule cloud run job
resource "google_cloud_scheduler_job" "playwright-cloudrun-job-scheduler" {
  attempt_deadline = "180s"
  description      = null
  name             = "playwright-cloudrun-job-scheduler-trigger"
  paused           = false
  project          = var.project_id
  region           = var.region
  schedule         = "0 * * * *" # once an hour on the hour
  time_zone        = "Etc/UTC"
  http_target {
    body        = null
    headers     = {}
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.playwright.name}:run"
    oauth_token {
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
      service_account_email = google_service_account.sa-name.email
    }
  }
  retry_config {
    max_backoff_duration = "3600s"
    max_doublings        = 5
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
    retry_count          = 0
  }
}

# alerting policy to alert when changes occur in the playwright job
resource "google_monitoring_alert_policy" "cloud_run_job_alert" {
  combiner              = "OR"
  display_name          = "cloud_run_job_error"
  enabled               = true
  # add notification channels
  notification_channels = [google_monitoring_notification_channel.sms_notification.id, google_monitoring_notification_channel.email_notification.id]
  project               = var.project_id
  severity              = "ERROR"
  user_labels           = {}
  alert_strategy {
    auto_close           = "604800s"
    notification_prompts = ["OPENED"]
    notification_rate_limit {
      period = "3600s"
    }
  }
  conditions {
    display_name = "Log match condition"
    condition_matched_log {
      filter           = "resource.type=\"cloud_run_job\"\nseverity>=ERROR"
      label_extractors = {}
    }
  }
}

resource "google_monitoring_notification_channel" "sms_notification" {
  description  = null
  display_name = "Phone SMS Notification"
  enabled      = true
  force_delete = false
  labels = {
    number = var.sms_notification
  }
  project     = "playwright-python"
  type        = "sms"
  user_labels = {}
}

resource "google_monitoring_notification_channel" "email_notification" {
  description  = null
  display_name = "Email Notification"
  enabled      = true
  force_delete = false
  labels = {
    email_address = var.email_notification
  }
  project     = "playwright-python"
  type        = "email"
  user_labels = {}
}