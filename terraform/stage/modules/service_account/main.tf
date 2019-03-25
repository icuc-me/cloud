
provider "google" {}

variable "susername" {
    description = "Service account username to reference in provider"
}

variable "sdisplayname" {
    description = "Display name to assign if creating service account"
    default = ""
}

variable "create" {
    description = "Create and manage the account 1 or not 0 (default)"
    default = "1"
}

variable "protect" {
    description = "Prevent account from being removed"
    default = "0"
}

data "google_project" "current" {}

// ref: https://www.terraform.io/docs/providers/google/r/google_service_account.html
resource "google_service_account" "service_user" {
    count = "${var.create == 1 && var.protect == 0 ? 1 : 0}"
    account_id = "${var.susername}"
    display_name = "${var.sdisplayname}"
    project = "${data.google_project.current.project_id}"
}

resource "google_service_account" "protected_service_user" {
    count = "${var.create == 1 && var.protect == 1 ? 1 : 0}"
    account_id = "${var.susername}"
    display_name = "${var.sdisplayname}"
    project = "${data.google_project.current.project_id}"
    lifecycle {
        prevent_destroy = true
        ignore_changes = true
    }
}

data "google_project" "self" {}

output "email" {
    // Cannot return actual email when var.create == 0
    value = "${var.susername}@${data.google_project.current.project_id}.iam.gserviceaccount.com"
    sensitive = true
}
