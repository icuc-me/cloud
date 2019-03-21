
// Main service account for managing environments
module "main_service_account" {
    source = "./modules/service_account"
    providers { google = "google" }
    susername = "${local.self["SUSERNAME"]}"
    create = "${local.is_prod}"
}

output "main_service_account" {
    value = "${module.main_service_account.email}"
    sensitive = true
}

module "main_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google" }
    roles_members = <<EOF
        roles/storage.admin=serviceAccount:${module.main_service_account.email};
        roles/compute.admin=serviceAccount:${module.main_service_account.email};
        roles/compute.networkAdmin=serviceAccount:${module.main_service_account.email};
        roles/iam.serviceAccountAdmin=serviceAccount:${module.main_service_account.email};
        roles/iam.serviceAccountUser=serviceAccount:${module.main_service_account.email};
        roles/resourcemanager.projectIamAdmin=serviceAccount:${module.main_service_account.email};
EOF
    create = "${local.is_prod}"
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

// Actual, uris for production-data
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
