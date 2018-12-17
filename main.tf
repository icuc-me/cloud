
# From CLI -backend-config="backend.auto.tfvars"
terraform {
    backend "gcs" {}
}

# From provider.auto.tfvars and backend.auto.tfvars
variable "credentials" {}
variable "project" {}
variable "region" {}
variable "zone" {}
variable "bucket" {}

provider "google" {
    credentials = "${var.credentials}"
    project = "${var.project}"
    region = "${var.region}"
    zone = "${var.zone}"
}

# Bucket for holding/locking terraform state
resource "google_storage_bucket" "terraform-state" {
    name = "${var.bucket}"
    project = "${var.project}"
    storage_class = "REGIONAL"
    location = "${var.region}"
}

