
provider "google" {}

variable "bucket_name" {
    description = "Name of the existing bucket containing strongbox(es)"
}

variable "strongbox_name" {
    description = "File name of the strongbox to manage"
}

variable "readers" {
    description = "List of IAM identities that should have read-access to strongbox"
    type = "list"
    default = []
}

variable "writers" {
    description = "List of IAM identities that should have write-access to strongbox"
    type = "list"
    default = []
}

variable "box_content" {
    description = "Contents to set inside of strongbox"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket_object.html
resource "google_storage_bucket_object" "strongbox" {
    bucket = "${var.bucket_name}"
    name   = "${var.strongbox_name}"
    content = "${var.box_content}"
    lifecycle {
        ignore_changes = ["id"]
    }
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_object_acl.html
resource "google_storage_object_acl" "strongbox_acl" {
    count = "${length(compact(var.readers)) > 0 || length(compact(var.writers)) > 0
               ? 1
               : 0}"
    bucket = "${google_storage_bucket_object.strongbox.bucket}"
    object = "${google_storage_bucket_object.strongbox.name}"
    role_entity = ["${concat(formatlist("READER:user-%s", compact(var.readers)),
                             formatlist("WRITER:user-%s",  compact(var.writers)))}"]
}

output "uri" {
    value = "gs://${var.bucket_name}/${var.strongbox_name}"
    sensitive = true
}