
// Resources used in all environments and not easily testable.

// ref: https://www.terraform.io/docs/providers/google/r/google_service_account.html
resource "google_service_account" "test-service-user" {
    account_id   = "${var.TEST_SECRETS["SUSERNAME"]}"
    // display_name = "${module.strong_unbox.contents["suser_display_name"]}"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    provider = "google.test"
}

resource "google_service_account" "stage-service-user" {
    account_id   = "${var.STAGE_SECRETS["SUSERNAME"]}"
    //display_name = "${module.strong_unbox.contents["suser_display_name"]}"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    provider = "google.stage"
}

resource "google_service_account" "prod-service-user" {
    account_id   = "${local.self["SUSERNAME"]}"
    //display_name = "${module.strong_unbox.contents["suser_display_name"]}"
    project = "${local.self["PROJECT"]}"
    provider = "google.prod"
}

/* NOT READY YET
// ref: https://www.terraform.io/docs/providers/google/r/google_project_iam.html
module "test_iam_bindings" {
    source = "./modules/projects_iam_bindings"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    role_members = "${module.strong_unbox.contents["test_iam_bindings"]}"
}
*/
