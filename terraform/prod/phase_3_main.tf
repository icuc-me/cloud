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

data "terraform_remote_state" "phase_2" {
    backend = "gcs"
    config {
        credentials = "${local.self["CREDENTIALS"]}"
        project = "${local.self["PROJECT"]}"
        region = "${local.self["REGION"]}"
        bucket = "${local.self["BUCKET"]}"
        prefix = "${local.self["PREFIX"]}"
    }
    workspace = "phase_2"
}

locals {
    strongbox_contents = "${data.terraform_remote_state.phase_2.strongbox_contents}"
    // In test & stage, this will be mock-uri's
    strongbox_uris = "${data.terraform_remote_state.phase_1.strongbox_uris}"
    fqdn = "${data.terraform_remote_state.phase_2.fqdn}"
    glue_zone = "${data.terraform_remote_state.phase_2.glue_zone}"
    canonical_legacy_domains = "${data.terraform_remote_state.phase_2.canonical_legacy_domains}"
}

// Set access controls on buckets and objects.  Mock buckets used in test & stage
module "strongbox_acls" {
    source = "./modules/strongbox_acls"
    providers { google = "google" }
    set_acls = "1"
    strongbox_uris = "${local.strongbox_uris}"
    env_readers = "${local.strongbox_contents["env_readers"]}"
}

output "strongbox_acls" {
    value = {
        object_readers = "${module.strongbox_acls.object_readers}"
        bucket_readers = "${module.strongbox_acls.bucket_readers}"
    }
    sensitive = true
}

// see also: phase_3_test.tf and phase_3_stage.tf
module "project_dns" {
    source = "./modules/project_dns"
    providers {  // N/B: In test & stage, these are NOT the actual named providers!
        google.test = "google.test"
        google.stage = "google.stage"
        google.prod = "google.prod"
    }
    domain_fqdn = "${local.fqdn}"
    glue_zone = "${local.glue_zone}"  // empty-string in prod. env
    legacy_domains = ["${local.canonical_legacy_domains}"]
    env_uuid = "${var.UUID}"
}

output "name_to_zone" {
    value = "${module.project_dns.name_to_zone}"
    sensitive = true
}

output "name_to_fqdn" {
    value = "${module.project_dns.name_to_fqdn}"
    sensitive = true
}

output "canonical_legacy_domains" {
    value = "${local.canonical_legacy_domains}"
    sensitive = true
}

output "legacy_shortnames" {
    value = ["${module.project_dns.legacy_shortnames}"]
    sensitive = true
}
output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
