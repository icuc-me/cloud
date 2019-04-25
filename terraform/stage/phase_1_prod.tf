locals {
    main_sa = "${var.PROD_SECRETS["SUSERNAME"]}@${var.PROD_SECRETS["PROJECT"]}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "test_main_svc_act_iam" {
    provider = "google.test"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    role = "roles/editor"
    member  = "serviceAccount:${local.main_sa}"
}

resource "google_project_iam_member" "stage_main_svc_act_iam" {
    provider = "google.stage"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    role = "roles/editor"
    member  = "serviceAccount:${local.main_sa}"
}

resource "google_project_iam_member" "prod_main_svc_act_iam" {
    provider = "google.prod"
    project = "${var.PROD_SECRETS["PROJECT"]}"
    role = "roles/editor"
    member  = "serviceAccount:${local.main_sa}"
}
