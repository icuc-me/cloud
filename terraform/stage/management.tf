
// Resources used in all environments but not easily testable.
// NEEDS PER-ENV MODIFICATION

/**** TEST ****/
module "test_service_account" {
    source = "./modules/service_account"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    susername = "${var.TEST_SECRETS["SUSERNAME"]}"
}
module "test_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["test_roles_members_bindings"]}"
}


/**** STAGE ****/
module "stage_service_account" {
    source = "./modules/service_account"
    providers { google = "google.stage" }
    env_name = "${var.ENV_NAME}"
    susername = "${var.STAGE_SECRETS["SUSERNAME"]}"
}
module "stage_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.stage" }
    env_name = "${var.ENV_NAME}"
    roles_members = "${module.strong_unbox.contents["stage_roles_members_bindings"]}"
}


/**** PROD ****/
// module "prod_service_account" {
//     source = "./modules/service_account"
//     providers { google = "google.prod" }
//     env_name = "${var.ENV_NAME}"
//     susername = "${var.PROD_SECRETS["SUSERNAME"]}"
// }
// module "prod_project_iam_binding" {
//     source = "./modules/project_iam_binding"
//     providers { google = "google.prod" }
//     env_name = "${var.ENV_NAME}"
//     roles_members = "${module.strong_unbox.contents["prod_roles_members_bindings"]}"
// }
