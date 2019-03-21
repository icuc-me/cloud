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

module "prod_project_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google.prod" }
    roles_members = "${local.strongbox_contents["prod_roles_members_bindings"]}"
    create = "${local.is_prod}"
}
