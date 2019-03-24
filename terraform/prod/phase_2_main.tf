data "terraform_remote_state" "phase_1" {
    backend = "gcs"
    config {
        credentials = "${local.self["CREDENTIALS"]}"
        project = "${local.self["PROJECT"]}"
        region = "${local.self["REGION"]}"
        bucket = "${local.self["BUCKET"]}"
        prefix = "${local.self["PREFIX"]}"
    }
    workspace = "phase_1"
}

locals {
    // In test & stage, this will be mock-uri's
    strongbox_uris = "${data.terraform_remote_state.phase_1.strongbox_uris}"
    strongbox_filenames = "${data.terraform_remote_state.phase_1.strongbox_filenames}"
}

// Actual decryption of this environments secrets
module "strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    // Actual strongbox URI (not mock)
    strongbox_uri = "${local.self["STRONGBOX"]}/${local.strongbox_filenames[var.ENV_NAME]}"
    strongkey = "${local.self["STRONGKEY"]}"
}

output "strongbox_contents" {
    value = "${module.strong_unbox.contents}"
    sensitive = true
}

// Verifies decryption works
module "mock_strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    // Mock strongbox unless env == prod
    strongbox_uri = "${local.strongbox_uris[var.ENV_NAME]}"
    strongkey = "${local.strongkeys[var.ENV_NAME]}"
}

// Verifies contents
output "mock_strongbox_contents" {
    value = "${module.mock_strong_unbox.contents}"
    sensitive = true
}

// CI Automation service account for test environment
module "test_ci_svc_act" {
    source = "./modules/service_account"
    providers { google = "google" }
    susername = "${module.strong_unbox.contents["test_ci_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["ci_suser_display_name"]}"
    create = "${local.is_prod}"
}

module "stage_ci_svc_act" {
    source = "./modules/service_account"
    providers { google = "google" }
    susername = "${module.strong_unbox.contents["stage_ci_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["ci_suser_display_name"]}"
    create = "${local.is_prod}"
}

module "prod_ci_svc_act" {
    source = "./modules/service_account"
    providers { google = "google" }
    susername = "${module.strong_unbox.contents["prod_ci_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["ci_suser_display_name"]}"
    create = "${local.is_prod}"
}

output "ci_svc_acts" {
    value = {
        test = "${module.test_ci_svc_act.email}"
        stage = "${module.stage_ci_svc_act.email}"
        prod = "${module.prod_ci_svc_act.email}"
    }
    sensitive = true
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
