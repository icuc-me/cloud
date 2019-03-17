
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

data "terraform_remote_state" "phase_3" {
    backend = "gcs"
    config {
        credentials = "${local.self["CREDENTIALS"]}"
        project = "${local.self["PROJECT"]}"
        region = "${local.self["REGION"]}"
        bucket = "${local.self["BUCKET"]}"
        prefix = "${local.self["PREFIX"]}"
    }
    workspace = "phase_3"
}

locals {
    strongbox_contents = "${data.terraform_remote_state.phase_2.strongbox_contents}"
    // In test & stage, this will be mock-uri's
    strongbox_uris = "${data.terraform_remote_state.phase_2.strongbox_uris}"
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

/* NEEDS PER-ENV MODIFICATION */
module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    roles_members = "${local.strongbox_contents["test_roles_members_bindings"]}"
    create = "${local.is_prod}"
}

module "stage_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.stage" }
    roles_members = "${local.strongbox_contents["stage_roles_members_bindings"]}"
    create = "${local.is_prod}"
}

// module "prod_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.prod" }
//     roles_members = "${local.strongbox_contents["prod_roles_members_bindings"]}"
//     create = "${local.is_prod}"
// }

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
