# Bucket for holding/locking terraform state
resource "google_storage_bucket" "test-bucket" {
    name = "test-${var.bucket}"
    project = "${var.project}"
    force_destroy = "${var.env_name == "prod" ? false : true}"
}
