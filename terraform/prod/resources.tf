
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

output "box_contents" { value = "${module.strong_unbox.contents}" }

resource "null_resource" "phase_2" {
    depends_on = ["module.strong_unbox"]
}

module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["test_roles_members_bindings"]}"
}

output "test_roles" { value = "${module.test_project_iam_binding.roles}" }
output "test_members" { value = "${module.test_project_iam_binding.members}" }

module "stage_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.stage" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["stage_roles_members_bindings"]}"
}

output "stage_roles" { value = "${module.stage_project_iam_binding.roles}" }
output "stage_members" { value = "${module.stage_project_iam_binding.members}" }

module "prod_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.prod" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["prod_roles_members_bindings"]}"
}

output "prod_roles" { value = "${module.prod_project_iam_binding.roles}" }
output "prod_members" { value = "${module.prod_project_iam_binding.members}" }

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
        "google_service_account.test-service-user",
        "google_service_account.stage-service-user",
        "google_service_account.prod-service-user",
        "module.test_project_iam_binding",
        "module.stage_project_iam_binding",
        "module.prod_project_iam_binding"
    ]
}
