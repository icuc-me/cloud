
provider "google" {}

variable "strongbox_uris" {
    description = "Map of environment name (test, stage, prod) to strongbox URI"
    type = "map"
}

variable "readers" {
    description = "Map of env. names (test, stage, prod) to service account e-mails"
    type = "map"
    default = {
        test = [],
        stage = [],
        prod = []
    }
}

variable "writers" {
    description = "Map of env. names (test, stage, prod) to service account e-mails"
    type = "map"
    default = {
        test = [],
        stage = [],
        prod = []
    }
}

module "test_strongbox_acls" {
    source = "./strongbox_acl"
    providers = { google = "google" }
    strongbox_uri = "${var.strongbox_uris["test"]}"
    readers = ["${var.readers["test"]}"]
    writers = ["${var.writers["test"]}"]
}

module "stage_strongbox_acls" {
    source = "./strongbox_acl"
    providers = { google = "google" }
    strongbox_uri = "${var.strongbox_uris["stage"]}"
    readers = ["${var.readers["stage"]}"]
    writers = ["${var.writers["stage"]}"]
}

module "prod_strongbox_acls" {
    source = "./strongbox_acl"
    providers = { google = "google" }
    strongbox_uri = "${var.strongbox_uris["prod"]}"
    readers = ["${var.readers["prod"]}"]
    writers = ["${var.writers["prod"]}"]
}

# TODO: Deal with "writers"
resource "google_storage_bucket_iam_binding" "strongbox" {
    bucket = "${element(split("/", var.strongbox_uris["prod"]), 2)}" #"
    role = "roles/storage.objectViewer"
    members = ["${formatlist("serviceAccount:%s",
                             compact(concat(var.readers["test"],
                                            var.readers["stage"],
                                            var.readers["prod"])))}"]
}
