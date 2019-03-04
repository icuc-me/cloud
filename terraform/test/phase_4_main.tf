
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
    // Actual strongbox contents
    strongbox_contents = "${data.terraform_remote_state.phase_2.strongbox_contents}"

    // matches strongbox_contents when env == prod
    mock_strongbox_contents = "${data.terraform_remote_state.phase_2.mock_strongbox_contents}"
}

module "strongbox_acls" {
    source = "./modules/strongbox_acls"
    providers { google = "google" }
    set_acls = "${local.is_prod}"
    // mock strongbox URIs, unless env == prod
    strongbox_uris = "${data.terraform_remote_state.phase_2.strongbox_uris}"
    env_readers = "${local.is_prod == 1
                     ? local.strongbox_contents["env_readers"]
                     : local.mock_strongbox_contents["env_readers"]}"
}

/* NEEDS PER-ENV MODIFICATION */
module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    roles_members = "${local.strongbox_contents["test_roles_members_bindings"]}"
}
// module "stage_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.stage" }
//     roles_members = "${local.strongbox_contents["stage_roles_members_bindings"]}"
// }
// module "prod_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.prod" }
//     roles_members = "${local.strongbox_contents["prod_roles_members_bindings"]}"
// }

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
