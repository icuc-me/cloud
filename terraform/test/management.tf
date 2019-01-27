
// Resources used in all environments but not easily testable.
// NEEDS PER-ENV MODIFICATION
//
// ref: https://www.terraform.io/docs/providers/google/r/google_service_account.html
// resource "google_service_account" "test-service-user" {
//     count = "${local.only_in_prod}"
//     account_id   = "${var.TEST_SECRETS["SUSERNAME"]}"
//     project = "${var.TEST_SECRETS["PROJECT"]}"
//     provider = "google.test"
//     lifecycle { prevent_destroy = true  }
// }
//
// resource "google_service_account" "stage-service-user" {
//     count = "${local.only_in_prod}"
//     account_id   = "${var.STAGE_SECRETS["SUSERNAME"]}"
//     project = "${var.STAGE_SECRETS["PROJECT"]}"
//     provider = "google.stage"
//     lifecycle { prevent_destroy = true  }
// }
//
// resource "google_service_account" "prod-service-user" {
//     count = "${local.only_in_prod}"
//     account_id   = "${var.PROD_SECRETS["SUSERNAME"]}"
//     project = "${var.PROD_SECRETS["PROJECT"]}"
//     provider = "google.prod"
//     lifecycle { prevent_destroy = true  }
// }
