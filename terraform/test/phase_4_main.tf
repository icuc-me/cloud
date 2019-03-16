
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
    mock_strongbox_contents = "${data.terraform_remote_state.phase_2.mock_strongbox_contents}"
}

module "strongbox_acls" {
    source = "./modules/strongbox_acls"
    providers { google = "google" }
    set_acls = "${local.is_prod}"  // don't set anything outside of prod
    // when ENV_NAME == prod: mock_strongbox == strongbox
    strongbox_uris = "${data.terraform_remote_state.phase_2.mock_strongbox_uris}"
    env_readers = "${local.mock_strongbox_contents["env_readers"]}"
}

output "strongbox_acls" {
    value = {
        object_readers = "${module.strongbox_acls.object_readers}"
        bucket_readers = "${module.strongbox_acls.bucket_readers}"
    }
}

/* NEEDS PER-ENV MODIFICATION */
module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    roles_members = "${local.strongbox_contents["test_roles_members_bindings"]}"
    create = "${local.is_prod}"
}

// module "stage_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.stage" }
//     roles_members = "${local.strongbox_contents["stage_roles_members_bindings"]}"
//     create = "${local.is_prod}"
// }
//
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
