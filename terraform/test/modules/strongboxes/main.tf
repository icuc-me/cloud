
provider "google" {}

variable "env_name_uuid" {
    description = "Unique id formed by the environment name, a '-', and a UUID"
}

variable "readers" {
    description = "Map of env. names (test, stage, prod) to service account e-mails"
    type = "map"
}

variable "strongbox" {
    description = "Bucket name containing strongbox file"
}

variable "strongkey" {
    description = "Encryption key securing contents of strongbox file"
}

locals {
    env_name = "${element(split("-", var.env_name_uuid), 0)}"
    env_uuid = "${element(split("-", var.env_name_uuid), 1)}"
    // Test and Stage Don't have write-access to production strongbox, use mock value
    non_prod_env_name_uuid = "${local.env_name}-mock-${uuid()}"
    non_prod_env_key = "TESTY-MC-TESTFACE"
}

module "strong_uri" {
    source = "../stronguri"
    strongbox = "${var.strongbox}"
}

resource "google_storage_bucket" "boxbucket" {
    name = "${local.env_name == "prod"
              ? module.strong_uri.bucket
              : local.non_prod_env_name_uuid}" // must actually be unique
    force_destroy = "${local.env_name == "prod"
                       ? 0
                       : 1}"
    lifecycle {
        ignore_changes = ["name"]
    }
}

data "external" "test_contents" {
    program = ["python", "${path.module}/strongbox.py"]
    query = {
        plaintext = "${file("${path.root}/test-strongbox.yml")}"
        strongbox = "${local.env_name == "prod" ? var.strongbox : local.non_prod_env_name_uuid}"
        strongkey = "${local.env_name == "prod" ? var.strongkey : local.non_prod_env_key}"
    }
}

data "external" "stage_contents" {
    program = ["python", "${path.module}/strongbox.py"]
    query = {
        plaintext = "${file("${path.root}/stage-strongbox.yml")}"
        strongbox = "${local.env_name == "prod" ? var.strongbox : local.non_prod_env_name_uuid}"
        strongkey = "${local.env_name == "prod" ? var.strongkey : local.non_prod_env_key}"
    }
}

data "external" "prod_contents" {
    program = ["python", "${path.module}/strongbox.py"]
    query = {
        plaintext = "${file("${path.root}/prod-strongbox.yml")}"
        strongbox = "${local.env_name == "prod" ? var.strongbox : local.non_prod_env_name_uuid}"
        strongkey = "${local.env_name == "prod" ? var.strongkey : local.non_prod_env_key}"
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
