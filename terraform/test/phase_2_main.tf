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
    providers { google = "google.test" }
    susername = "${module.strong_unbox.contents["test_ci_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["ci_suser_display_name"]}"
    create = "${local.is_prod}"
}

module "stage_ci_svc_act" {
    source = "./modules/service_account"
    providers { google = "google.stage" }
    susername = "${module.strong_unbox.contents["stage_ci_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["ci_suser_display_name"]}"
    create = "${local.is_prod}"
}

module "prod_ci_svc_act" {
    source = "./modules/service_account"
    providers { google = "google.prod" }
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

module "test_img_svc_act" {
    source = "./modules/service_account"
    providers { google = "google.test" }
    susername = "${module.strong_unbox.contents["test_img_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["img_suser_display_name"]}"
    create = "${local.is_prod}"
}

module "stage_img_svc_act" {
    source = "./modules/service_account"
    providers { google = "google.stage" }
    susername = "${module.strong_unbox.contents["stage_img_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["img_suser_display_name"]}"
    create = "${local.is_prod}"
}

module "prod_img_svc_act" {
    source = "./modules/service_account"
    providers { google = "google.prod" }
    susername = "${module.strong_unbox.contents["prod_img_susername"]}"
    sdisplayname = "${module.strong_unbox.contents["img_suser_display_name"]}"
    create = "${local.is_prod}"
}

output "img_svc_acts" {
    value = {
        test = "${module.test_img_svc_act.email}"
        stage = "${module.stage_img_svc_act.email}"
        prod = "${module.prod_img_svc_act.email}"
    }
    sensitive = true
}

// Workaround calculated-count problems in subsequent phases
locals {
    e = ""
    c = ","
    d = "."
    h = "-"
    // FQDN for stage and test assumed to contain their subdomain names,
    // but need to add UUID to prevent clashes.
    // see modules/project_dns/notes.txt
    fqdn = "${local.is_prod== 1
              ? module.strong_unbox.contents["fqdn"]
              : join(local.d, list(var.UUID, module.strong_unbox.contents["fqdn"]))}"
    fqdn_names = ["${split(local.d, local.fqdn)}"]
    fqdn_parent = "${join(local.d, slice(local.fqdn_names, 1, length(local.fqdn_names)))}"
    // Needed to attach e.g test_123abc.test.example.com into test.example.com (or similar for stage)
    glue_zone = "${local.is_prod == 1
                   ? local.e
                   : replace(local.fqdn_parent, local.d, local.h)}"
    // assumed to be shortnames unless prod-environment
    legacy_domains = ["${split(local.c, module.strong_unbox.contents["legacy_domains"])}"]
    // Conditionals cannot return lists, only strings, use fomatlist() as workaround
    t = "%s"
    legacy_domain_fmt = "${local.is_prod == 1
                           ? local.t
                           : join(local.d, list(local.t, local.fqdn))}"
    canonical_legacy_domains = ["${formatlist(local.legacy_domain_fmt, local.legacy_domains)}"]
}

output "fqdn" {
    value = "${local.fqdn}"
    sensitive = true
}

output "glue_zone" {
    value = "${local.glue_zone}"
    sensitive = true
}

output "canonical_legacy_domains" {
    value = "${local.canonical_legacy_domains}"
    sensitive = true
}
