
provider "google" {}

variable "susername" {
    description = "Service account username to reference in provider"
}

//ref: https://www.terraform.io/docs/providers/google/d/datasource_google_service_account.html
data "google_service_account" "susername" {
    count = "${var.susername != "" ? 1 : 0}"
    account_id = "${var.susername}"
}

output "email" {
    value = "${data.google_service_account.susername.0.email}"
    sensitive = true
}
