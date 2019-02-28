
provider "google" {}

variable "bucket_name" {
    description = "Name of the existing bucket containing strongbox(es)"
}

variable "strongbox_name" {
    description = "File name of the strongbox to manage"
}

variable "box_content" {
    description = "Contents to set inside of strongbox"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket_object.html
resource "google_storage_bucket_object" "strongbox" {
    bucket = "${var.bucket_name}"
    name   = "${var.strongbox_name}"
    content = "${var.box_content}"
}

output "uri" {
    value = "gs://${var.bucket_name}/${var.strongbox_name}"
    sensitive = true
}
