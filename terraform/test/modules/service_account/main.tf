
provider "google" {}

variable "env_name" {
    description = "Name of the current environment (test, stage, or prod)"
}

variable "susername" {
    description = "Service account username to reference in provider"
}

variable "sdisplayname" {
    description = "Display name to assign if creating service account"
    default = ""
}

locals {
    is_prod = "${var.env_name == "prod"
                 ? 1
                 : 0}"
    only_in_prod = "${local.is_prod
                      ? 1
                      : 0}"
}

data "google_project" "current" {}

// ref: https://www.terraform.io/docs/providers/google/r/google_service_account.html
resource "google_service_account" "service_user" {
    count = "${local.only_in_prod}"
    account_id   = "${var.susername}"
    display_name = "${var.sdisplayname}"
    project = "${data.google_project.current.project_id}"
    lifecycle { prevent_destroy = true }
}

// ref: https://www.terraform.io/docs/providers/google/d/datasource_google_service_account.html
data "google_service_account" "service_user" {
    account_id = "${var.susername}"
}

output "email" {
    value = "${data.google_service_account.service_user.email}"
    sensitive = true
}
