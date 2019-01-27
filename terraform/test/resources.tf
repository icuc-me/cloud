
module "strongboxes" {
    source = "./modules/strongboxes"
    providers { google = "google" }
    readers = "${local.strongbox_readers}"
    strongbox = "${local.is_prod == 1
                   ? local.self["STRONGBOX"]
                   : local.mock_strongbox}"
    strongkeys = "${local.strongkeys}"
    force_destroy = "${local.is_prod == 1
                       ? 0
                       : 1}"
}

// Required as workaround until https://github.com/hashicorp/terraform/issues/4149
resource "null_resource" "preload" {
    depends_on = [
        "google_service_account.test-service-user",
        // "google_service_account.stage-service-user",
        // "google_service_account.prod-service-user",
        "module.strongboxes"
    ]
}

module "strong_unbox" {
    source = "./modules/strong_unbox"
    providers { google = "google" }
    credentials = "${local.self["CREDENTIALS"]}"
    strongbox = "${format("%s/%s",
                          local.self["STRONGBOX"],
                          module.strongboxes.filenames[var.ENV_NAME])}"
    strongkey = "${local.self["STRONGKEY"]}"
}

// output "box_contents" { value = "${module.strong_unbox.contents}" }

module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["test_roles_members_bindings"]}"
}

// output "test_roles" { value = "${module.test_project_iam_binding.roles}" }
// output "test_members" { value = "${module.test_project_iam_binding.members}" }

// module "stage_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.stage" }
//     env_name = "${var.ENV_NAME}"
//     roles_members = "${module.strong_unbox.contents["stage_roles_members_bindings"]}"
// }

// output "stage_roles" { value = "${module.stage_project_iam_binding.roles}" }
// output "stage_members" { value = "${module.stage_project_iam_binding.members}" }

// module "prod_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.prod" }
//     env_name = "${var.ENV_NAME}"
//     roles_members = "${module.strong_unbox.contents["prod_roles_members_bindings"]}"
// }

// output "prod_roles" { value = "${module.prod_project_iam_binding.roles}" }
// output "prod_members" { value = "${module.prod_project_iam_binding.members}" }

/* NOT READY YET
module "gateway" {
    source = "./modules/gateway"
    providers { google = "google" }
    env_name = "${var.ENV_NAME}"
    env_uuid = "${var.UUID}"
}
*/
