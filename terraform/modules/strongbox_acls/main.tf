
provider "google" {}

variable "strongbox_uris" {
    description = "Map of env. name (test, stage, prod) to complete strongbox URI (including bucket)"
    type = "map"
}

variable "env_readers" {
    description = <<EOF
Encoded map of list of strings.  Map keys are env. names (test, stage, prod), separated by ';'.
Map values separated from keys by '=', and must be a non-empty list in CSV form, containing
valid service-account identities to grant read-access to the cooresponding strongbox
bucket for the environment (test, stage, or prod)
EOF
}

variable "set_acls" {
    description = "When set to 1, actually set defined ACLs on buckets and objects"
    default = "0"
}

locals {
    env_names = ["test", "stage", "prod"]
    d = "/"  // hard to escape
    c = ","
}

data "template_file" "bucket_names" {
    count = 3
    template = "${element(split(local.d, lookup(var.strongbox_uris, local.env_names[count.index])), 2)}"
}

data "template_file" "object_names" {
    count = 3
    // easier than slicing
    template = "${replace(lookup(var.strongbox_uris, local.env_names[count.index]),
                          format("gs:%s%s%s%s",
                                 local.d,
                                 local.d,
                                 element(data.template_file.bucket_names.*.rendered, count.index),
                                 local.d),
                          "")}"
}

module "env_readers" {
    source = "../keys_values"
    keys_values = ["${compact(split(";", trimspace(var.env_readers)))}"]
    length = 3
}

locals {
    env_readers = "${zipmap(module.env_readers.keys, module.env_readers.values)}"
}

data "template_file" "id_csv" {
    count = 3
    template = "${lookup(local.env_readers, local.env_names[count.index])}"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_object_acl.html
resource "google_storage_object_acl" "strongbox_acl" {
    count = "${var.set_acls == 1
               ? 3
               : 0}"
    bucket = "${element(data.template_file.bucket_names.*.rendered, count.index)}"
    object= "${element(data.template_file.object_names.*.rendered, count.index)}"
    role_entity = ["${formatlist("READER:user-%s",
                                 compact(distinct(split(local.c,
                                                        element(data.template_file.id_csv.*.rendered,
                                                                count.index)))))}"]
}

output "strongbox_acls" {
    value = "${zipmap(data.template_file.object_names.*.rendered,
                      data.template_file.id_csv.*.rendered)}"
    sensitive = true
}

locals {
    unique_buckets = "${distinct(data.template_file.bucket_names.*.rendered)}"
}

data "template_file" "bucket_readers" {
    count = "${length(local.unique_buckets)}"
    // keys do not have to be unique
    template = "${join(local.c, matchkeys(data.template_file.id_csv.*.rendered,
                                          data.template_file.bucket_names.*.rendered,
                                          list(local.unique_buckets[count.index])))}"
}

data "template_file" "unique_bucket_readers" {
    count = "${length(local.unique_buckets)}"
    template = "${join(local.c,
                       compact(distinct(split(local.c,
                                              element(data.template_file.bucket_readers.*.rendered,
                                                      count.index)))))}"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_bucket_iam.html
resource "google_storage_bucket_iam_binding" "strongbox" {
    count = "${var.set_acls == 1
               ? length(local.unique_buckets)
               : 0}"
    bucket = "${element(local.unique_buckets, count.index)}"
    role = "roles/storage.objectViewer"
    members = ["${split(local.c,
                        element(data.template_file.unique_bucket_readers.*.rendered,
                                count.index))}"]
}

output "boxbucket_acls" {
    value = "${zipmap(local.unique_buckets,
                      data.template_file.unique_bucket_readers.*.rendered)}"
    sensitive = true
}
