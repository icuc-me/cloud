
module "strongboxes" {
    source = "./modules/strongboxes"
    providers { google = "google.stage" }
    readers = "${local.strongbox_readers}"
    strongbox = "${local.strongbox}"
    strongkeys = "${local.strongkeys}"
    force_destroy = "${var.ENV_NAME == "prod" ? 0 : 1 }"
}

resource "null_resource" "phase_1" {
    depends_on = ["module.strongboxes"]
}

module "strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google.stage" }
    credentials = "${local.self["CREDENTIALS"]}"
    strongbox = "${module.strongboxes.uris[var.ENV_NAME]}"
    strongkey = "${local.strongkeys[var.ENV_NAME]}"
}

resource "null_resource" "phase_2" {
    depends_on = ["module.strong_unbox"]
}

module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["test_roles_members_bindings"]}"
}

module "stage_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.stage" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["stage_roles_members_bindings"]}"
}

/* NOT READY YET
module "gateway" {
    source = "./modules/gateway"
    providers { google = "google" }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
}
*/

resource "null_resource" "phase_3" {
    depends_on = [
        "null_resource.phase_2",
        "module.test_project_iam_binding",
        "module.stage_project_iam_binding"
    ]
}
