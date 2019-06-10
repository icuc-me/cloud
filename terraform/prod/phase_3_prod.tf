locals {
    ci_svc_acts = "${data.terraform_remote_state.phase_2.ci_svc_acts}"
    ci_act_roles = [
        "roles/storage.admin", "roles/compute.admin", "roles/compute.networkAdmin",
        "roles/iam.serviceAccountUser", "roles/dns.admin"
    ]

    img_svc_acts = "${data.terraform_remote_state.phase_2.img_svc_acts}"
    img_act_roles = [
        "roles/compute.admin", "roles/iam.serviceAccountUser"
    ]
}

// ref: https://www.terraform.io/docs/providers/google/r/google_project_iam.html
resource "google_project_iam_member" "test_ci_svc_act_iam" {
    provider = "google.test"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    count = "${length(local.ci_act_roles)}"
    role = "${local.ci_act_roles[count.index]}"
    member  = "serviceAccount:${local.ci_svc_acts["test"]}"
}

resource "google_project_iam_member" "test_img_svc_act_iam" {
    provider = "google.test"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    count = "${length(local.img_act_roles)}"
    role = "${local.img_act_roles[count.index]}"
    member  = "serviceAccount:${local.img_svc_acts["test"]}"
}

resource "google_project_iam_member" "stage_ci_svc_act_iam" {
    provider = "google.stage"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    count = "${length(local.ci_act_roles)}"
    role = "${local.ci_act_roles[count.index]}"
    member  = "serviceAccount:${local.ci_svc_acts["stage"]}"
}

resource "google_project_iam_member" "stage_img_svc_act_iam" {
    provider = "google.stage"
    project = "${var.STAGE_SECRETS["PROJECT"]}"
    count = "${length(local.img_act_roles)}"
    role = "${local.img_act_roles[count.index]}"
    member  = "serviceAccount:${local.img_svc_acts["stage"]}"
}

resource "google_project_iam_member" "prod_ci_svc_act_iam" {
    provider = "google.prod"
    project = "${var.PROD_SECRETS["PROJECT"]}"
    count = "${length(local.ci_act_roles)}"
    role = "${local.ci_act_roles[count.index]}"
    member  = "serviceAccount:${local.ci_svc_acts["prod"]}"
}

resource "google_project_iam_member" "prod_img_svc_act_iam" {
    provider = "google.prod"
    project = "${var.PROD_SECRETS["PROJECT"]}"
    count = "${length(local.img_act_roles)}"
    role = "${local.img_act_roles[count.index]}"
    member  = "serviceAccount:${local.img_svc_acts["prod"]}"
}

output "ci_svc_act_iam" {
    value = {
        test = ["${google_project_iam_member.test_ci_svc_act_iam.*.role}"],
        stage = ["${google_project_iam_member.stage_ci_svc_act_iam.*.role}"],
        prod = ["${google_project_iam_member.prod_ci_svc_act_iam.*.role}"],
    }
    sensitive = true
}
