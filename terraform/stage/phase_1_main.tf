
// Main service account for managing environments
module "main_service_account" {
    source = "./modules/service_account"
    providers { google = "google" }
    susername = "${local.self["SUSERNAME"]}"
    create = "${local.is_prod}"
}

module "main_iam_binding" {
    source = "./modules/project_iam_binding"
    providers { google = "google" }
    roles_members = <<EOF
        roles/storage.admin=serviceAccount:${module.main_service_account.email};
        roles/compute.admin=serviceAccount:${module.main_service_account.email};
        roles/compute.networkAdmin=serviceAccount:${module.main_service_account.email};
        roles/iam.serviceAccountAdmin=serviceAccount:${module.main_service_account.email};
        roles/iam.serviceAccountUser=serviceAccount:${module.main_service_account.email};
        roles/resourcemanager.projectIamAdmin=serviceAccount:${module.main_service_account.email};
EOF
    create = "${local.is_prod}"
}

output "main_service_account" {
    value = "${module.main_service_account.email}"
    sensitive = true
}
