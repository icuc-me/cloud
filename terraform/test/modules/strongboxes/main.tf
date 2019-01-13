
provider "google" {}

variable "env_name" {
    description = "Name of the current environment (test, stage, or prod)"
}

variable "readers" {
    description = "Map of env_name to list of storage.objectViewer identities"
    type = "map"
}

variable "writers" {
    description = "Map of env_name to list of storage.objectCreator identities"
    type = "map"
}

locals {
    env_names = ["test", "stage", "prod"]  // order is significant
    // one bucket for this env, and one for each lower level env
    strongbox_count = "${var.env_name == "prod" ? 3 : var.env_name == "stage" ? 2 : 1}"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket.html
resource "google_storage_bucket" "strongbox" {
    count = "${local.strongbox_count}"  // index into env_names
    lifecycle = {
        ignore_changes = "name"
    }
    name = "${element(local.env_names, count.index)}_strongbox_${uuid()}"
    // prod bucket destruction should fail
    force_destroy = "${var.env_name == "prod" ? "false" : "true"}"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket_iam.html
resource "google_storage_bucket_iam_binding" "reader_bindings" {
    count = "${local.strongbox_count}"  // index into env_names
    bucket = "${google_storage_bucket.strongbox.*.name[count.index]}"
    role   = "roles/storage.objectViewer"
    members = ["${var.readers[element(local.env_names, count.index)]}"]
}

resource "google_storage_bucket_iam_binding" "writer_bindings" {
    count = "${local.strongbox_count}"  // index into env_names
    bucket = "${google_storage_bucket.strongbox.*.name[count.index]}"
    role   = "roles/storage.objectCreator"
    members = ["${var.readers[element(local.env_names, count.index)]}"]
}

output "uris" {
    value = "${zipmap(slice(local.env_names, 0, local.strongbox_count),
                      google_storage_bucket.strongbox.*.url)}"
    sensitive = true
}
