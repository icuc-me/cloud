
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
    strongbox_uris = "${data.terraform_remote_state.phase_2.strongbox_uris}"
    ci_svc_acts = "${data.terraform_remote_state.phase_3.ci_svc_acts}"
    /* NEEDS PER-ENV MODIFICATION */
    strongbox_readers = {
        test = ["${local.ci_svc_acts["test"]}"],
        stage = [],
        prod = [],
    }
}

module "strongboxes_acls" {
    source = "./modules/strongboxes_acls"
    providers { google = "google" }
    strongbox_uris = "${local.strongbox_uris}"
    readers = "${local.strongbox_readers}"
}

/* NEEDS PER-ENV MODIFICATION */
module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${local.strongbox_contents["test_roles_members_bindings"]}"
}
// module "stage_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.stage" }
//     env_name = "${var.ENV_NAME}"
//     roles_members = "${local.strongbox_contents["stage_roles_members_bindings"]}"
// }
// module "prod_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.prod" }
//     env_name = "${var.ENV_NAME}"
//     roles_members = "${local.strongbox_contents["prod_roles_members_bindings"]}"
// }

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
