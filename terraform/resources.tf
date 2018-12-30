# Bucket for holding/locking terraform state
resource "google_storage_bucket" "terraform-state" {
    name = "${var.bucket}"
    project = "${var.project}"
    force_destroy = "${var.env_name == "prod" ? false : true}"
}
