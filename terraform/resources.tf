# Bucket for holding/locking terraform state
resource "google_storage_bucket" "terraform-state" {
    name = "${var.bucket}"
    project = "${var.project}"
    storage_class = "REGIONAL"
    location = "${var.region}"
    force_destroy = "${var.env_name == "prod" ? false : true}"
}
