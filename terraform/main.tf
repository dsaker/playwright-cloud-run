resource "google_artifact_registry_repository" "playwright-python" {
  location      = var.region
  repository_id = var.repository_id
  description   = "example docker repository for python playwright test scripts"
  format        = "DOCKER"
}

locals {
  l = google_artifact_registry_repository.playwright-python.location
  p = google_artifact_registry_repository.playwright-python.project
  r = google_artifact_registry_repository.playwright-python.repository_id
  image = "${local.l}-docker.pkg.dev/${local.p}/${local.r}/${var.image_name}:${var.image_version}"
}



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

resource "google_service_account" "sa-name" {
  account_id = "cloud-run-invoker"
}

resource "google_project_iam_member" "cloud-run-invoker" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}

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
