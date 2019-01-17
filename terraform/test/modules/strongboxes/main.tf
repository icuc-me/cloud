
provider "google" {}

variable "env_name_uuid" {
    description = "Unique id formed by the environment name, a '-', and a UUID"
}

variable "readers" {
    description = "Map of env. names (test, stage, prod) to service account e-mails"
    type = "map"
}

locals {
    env_name = "${element(split("-", var.env_name_uuid), 0)}"
    env_uuid = "${element(split("-", var.env_name_uuid), 1)}"
    non_prod_env_name_uuid = ["${local.env_name}", "${uuid()}"]
}

resource "google_storage_bucket" "boxbucket" {
    name = "${local.env_name == "prod"
              ? var.env_name_uuid
              : join("-", local.non_prod_env_name_uuid)}" // must actually be unique
    force_destroy = "${local.env_name == "prod"
                       ? 0
                       : 1}"
    lifecycle {
        ignore_changes = ["name"]
    }
}

module "test_strongbox" {
    providers = { google = "google" }
    source = "./modules/strongbox"
    bucket_name = "${google_storage_bucket.boxbucket.name}"
    strongbox_name = "test_strongbox.bz2.pgp"
    readers = "${var.readers["test"]}"
    writers = []
}

module "stage_strongbox" {
    providers = { google = "google" }
    source = "./modules/strongbox"
    bucket_name = "${google_storage_bucket.boxbucket.name}"
    strongbox_name = "stage_strongbox.bz2.pgp"
    readers = "${var.readers["stage"]}"
    writers = []
}

module "prod_strongbox" {
    providers = { google = "google" }
    source = "./modules/strongbox"
    bucket_name = "${google_storage_bucket.boxbucket.name}"
    strongbox_name = "prod_strongbox.bz2.pgp"
    readers = "${var.readers["prod"]}"
    writers = []
}
