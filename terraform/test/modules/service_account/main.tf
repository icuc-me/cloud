
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
    default = "0"
}

data "google_project" "current" {}

// ref: https://www.terraform.io/docs/providers/google/r/google_service_account.html
resource "google_service_account" "service_user" {
    count = "${var.create}"
    account_id = "${var.susername}"
    display_name = "${var.sdisplayname}"
    project = "${data.google_project.current.project_id}"
}

data "google_project" "self" {}

output "email" {
    // KISS: format is known, testing var.create is complex
    value = "${var.susername}@${data.google_project.current.project_id}.iam.gserviceaccount.com"
    sensitive = true
}
