
module "strongboxes" {
    source = "./modules/strongboxes"
    providers { google = "google" }
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
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    strongbox = "${module.strongboxes.uris[var.ENV_NAME]}"
    strongkey = "${local.strongkeys[var.ENV_NAME]}"
}

resource "null_resource" "phase_2" {
    depends_on = ["module.strong_unbox"]
}

module "project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["roles_members_bindings"]}"
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
    depends_on = ["null_resource.phase_2", "module.project_iam_binding"]
}

output "strongboxes" {
    value = "${module.strongboxes.uris}"
}

output "roles" {
    value = ["${module.project_iam_binding.roles}"]
}

output "members" {
    value = ["${module.project_iam_binding.members}"]
}
