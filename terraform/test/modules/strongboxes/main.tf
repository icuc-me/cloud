
provider "google" {}

variable "strongbox" {
    description = "Bucket uri containing strongbox files"
}

variable "strongkeys" {
    description = "Encryption keys securing contents of strongbox file for each env (test, stage, prod)"
    type = "map"
}

variable "readers" {
    description = "Map of env. names (test, stage, prod) to service account e-mails"
    type = "map"
}

variable "force_destroy" {
    description = "Should the strongbox bucket be force-destroyed"
    default = "0"
}

locals {
    delimiter = "/"
    components = ["${split(local.delimiter, var.strongbox)}"]
    boxbucket = "${local.components[2]}"
}

resource "google_storage_bucket" "boxbucket" {
    name = "${local.boxbucket}"
    force_destroy = "${var.force_destroy}"
}

data "external" "test_contents" {
    program = ["python", "${path.module}/strongbox.py"]
    query = {
        plaintext = "${file("${path.root}/test-strongbox.yml")}"
        strongbox = "${var.strongbox}"
        strongkey = "${var.strongkeys["test"]}"
    }
}

data "external" "stage_contents" {
    program = ["python", "${path.module}/strongbox.py"]
    query = {
        plaintext = "${file("${path.root}/stage-strongbox.yml")}"
        strongbox = "${var.strongbox}"
        strongkey = "${var.strongkeys["stage"]}"
    }
}

data "external" "prod_contents" {
    program = ["python", "${path.module}/strongbox.py"]
    query = {
        plaintext = "${file("${path.root}/prod-strongbox.yml")}"
        strongbox = "${var.strongbox}"
        strongkey = "${var.strongkeys["prod"]}"
    }
}

module "test_strongbox" {
    providers = { google = "google" }
    source = "../strongbox"
    bucket_name = "${google_storage_bucket.boxbucket.name}"
    strongbox_name = "test-strongbox.json.bz2.pgp"
    readers = "${var.readers["test"]}"
    box_content = "${data.external.test_contents.result["encrypted"]}"
}

module "stage_strongbox" {
    providers = { google = "google" }
    source = "../strongbox"
    bucket_name = "${google_storage_bucket.boxbucket.name}"
    strongbox_name = "stage-strongbox.json.bz2.pgp"
    readers = "${var.readers["stage"]}"
    box_content = "${data.external.stage_contents.result["encrypted"]}"
}

module "prod_strongbox" {
    providers = { google = "google" }
    source = "../strongbox"
    bucket_name = "${google_storage_bucket.boxbucket.name}"
    strongbox_name = "prod-strongbox.json.bz2.pgp"
    readers = "${var.readers["prod"]}"
    box_content = "${data.external.prod_contents.result["encrypted"]}"
}

output "uris" {
    value = {
        test = "${module.test_strongbox.uri}"
        stage = "${module.stage_strongbox.uri}"
        prod = "${module.prod_strongbox.uri}"
    }
}
