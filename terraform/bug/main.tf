terraform {
    backend "gcs" {
        bucket = "0a68535186d141059ccedb3fe848c801"
        credentials = "/home/cevich/devel/play/cloud/secrets/test-somebody.json"
        project = "test-cloud-icuc-me"
        region = "us-east1"
    }
    required_version = "~> 0.11"
}

provider "google" {
    version = "~> 1.20"
    credentials = "/home/cevich/devel/play/cloud/secrets/test-somebody.json"
    project = "test-cloud-icuc-me"
    region = "us-east1"
    zone = "us-east1-c"
}

resource "google_storage_bucket" "bucket" {
    name = "277d1ebdbd354280be2963ef63d659f9"
}

resource "google_storage_bucket_object" "object" {
  count = 5
  bucket = "${google_storage_bucket.bucket.name}"
  name   = "main-${count.index}"
  source = "./main.tf"
}

locals {
    other_service_email = "somebody@stage-cloud-icuc-me.iam.gserviceaccount.com"
}

resource "google_storage_object_acl" "acl" {
    bucket = "${google_storage_bucket.bucket.name}"
    object = "${google_storage_bucket_object.object.*.name[count.index]}"
    role_entity = ["READER:user-${local.other_service_email}",
                   "OWNER:user-${local.other_service_email}"]
}
