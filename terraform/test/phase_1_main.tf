
// Main service account for managing this environment and lower
module "main_service_account" {
    source = "./modules/service_account"
    providers { google = "google" }
    susername = "${local.self["SUSERNAME"]}"
    create = "${local.is_prod}"
}

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
