
# See $GOOGLE_APPLICATION_CREDENTIALS
#     GOOGLE_PROJECT
#     GOOGLE_REGION
#     GOOGLE_ZONE
provider "google" {}

# Access to project, region, and access_token
data "google_client_config" "current" {}

# Bucket for holding/locking terraform state
resource "google_storage_bucket" "terraform-state" {
    name = "me-icuc-test-terraform-state"
    project = "${data.google_client_config.current.project}"
    storage_class = "REGIONAL"
    location = "${data.google_client_config.current.region}"
}
