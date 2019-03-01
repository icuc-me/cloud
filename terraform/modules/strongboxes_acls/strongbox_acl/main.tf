
provider "google" {}

variable "strongbox_uri" {
    description = "Complete URI to strongbox bucket and object"
}

variable "readers" {
    description = "List of IAM identities that should have read-access to strongbox"
    type = "list"
    default = []
}

variable "writers" {
    description = "List of IAM identities that should have write-access to strongbox"
    type = "list"
    default = []
}

locals {
    delimiter = "/"
    uri_components = ["${split(local.delimiter, var.strongbox_uri)}"]
    bucket_object = ["${slice(local.uri_components, 2, length(local.uri_components))}"]
    boxbucket = "${local.bucket_object[0]}"
    boxobject = "${join(local.delimiter, slice(local.bucket_object, 1, length(local.bucket_object)))}"
    role_entity = ["${concat(formatlist("READER:user-%s", compact(var.readers)),
                             formatlist("OWNER:user-%s", compact(var.writers)))}"]
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_object_acl.html
resource "google_storage_object_acl" "strongbox_acl" {
    count = "${join(",", compact(local.role_entity)) == "" ? 0 : 1}"
    bucket = "${local.boxbucket}"
    object = "${local.boxobject}"
    role_entity = ["${local.role_entity}"]
}

output "roles" {
    value = "${local.role_entity}"
    sensitive = true
}
