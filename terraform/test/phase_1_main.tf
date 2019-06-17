
// Main service account for managing all environments
// N/B: THIS MUST BE IMPORTED & ROLES BOUND MANUALLY: see secrets/README.md
module "main_service_account" {
    source = "./modules/service_account"
    providers { google = "google" }
    susername = "${local.self["SUSERNAME"]}"
    create = "${local.is_prod}"
    protect = "${local.is_prod}"
}

output "main_service_account" {
    value = "${module.main_service_account.email}"
    sensitive = true
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket_iam.html
resource "google_storage_bucket_iam_binding" "main_bucket_admin" {
    count = "${local.is_prod}"
    bucket = "${local.self["BUCKET"]}"
    role = "roles/storage.admin"
    members = ["serviceAccount:${module.main_service_account.email}"]
}

resource "google_storage_bucket_iam_binding" "main_bucket_object_admin" {
    count = "${local.is_prod}"
    bucket = "${local.self["BUCKET"]}"
    role = "roles/storage.objectAdmin"
    members = ["serviceAccount:${module.main_service_account.email}"]
}

// Persistent, encrypted sensitive data store for all environments
// (fake/mock values used in test & stage)
module "strongboxes" {
    source = "./modules/strongboxes"
    providers { google = "google" }
    strongbox = "${local.is_prod == 1
                   ? local.self["STRONGBOX"]
                   : local.mock_strongbox}"
    strongkeys = "${local.strongkeys}"
    force_destroy = "${local.is_prod == 1
                       ? 0
                       : 1}"
}

locals {
    actual_uris = {
        test = "${var.TEST_SECRETS["STRONGBOX"]}/${module.strongboxes.filenames["test"]}"
        stage = "${var.STAGE_SECRETS["STRONGBOX"]}/${module.strongboxes.filenames["stage"]}"
        prod = "${var.PROD_SECRETS["STRONGBOX"]}/${module.strongboxes.filenames["prod"]}"
    }
    mock_uris = {
        test = "${module.strongboxes.uris["test"]}"
        stage = "${module.strongboxes.uris["stage"]}"
        prod = "${module.strongboxes.uris["prod"]}"
    }
}

output "strongbox_uris" {
    value = {
        test = "${local.is_prod == 1
                  ? local.actual_uris["test"]
                  : local.mock_uris["test"]}"
        stage = "${local.is_prod == 1
                   ? local.actual_uris["stage"]
                   : local.mock_uris["stage"]}"
        prod = "${local.is_prod == 1
                   ? local.actual_uris["prod"]
                   : module.strongboxes.uris["prod"]}"
    }
    sensitive = true
}

output "strongbox_filenames" {
    value = {
        test = "${module.strongboxes.filenames["test"]}",
        stage = "${module.strongboxes.filenames["stage"]}",
        prod = "${module.strongboxes.filenames["prod"]}",
    }
    sensitive = true
}

output "env_name" {
    value = "${var.ENV_NAME}"
    sensitive = true
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
