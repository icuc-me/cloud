

# From provider.auto.tfvars and backend.auto.tfvars
variable "credentials" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#credentials"
}
variable "project" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#project"
}
variable "region" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#region"
}
variable "zone" {
    description = "https://www.terraform.io/docs/providers/google/provider_reference.html#zone"
}
variable "bucket" {
    description = "https://www.terraform.io/docs/backends/types/gcs.html#configuration-variables"
}

# From command-line
variable "env_name" {
    description = "Name of environment to operating in (test, stage, prod)"
}

# From CLI -backend-config="backend.auto.tfvars"
terraform {
    backend "gcs" {}
}

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

