
provider "google" {}

variable "strongbox_uris" {
    description = "Map of env. name (test, stage, prod) to complete strongbox URI (including bucket)"
    type = "map"
}

variable "env_readers" {
    description = "Format accepted by map_csv module"
}

variable "set_acls" {
    description = "When set to 1, actually set defined ACLs on buckets and objects"
    default = "0"
}

module "env_readers" {
    source = "../map_csv"
    string = "${var.env_readers}"
}

locals {
    d = "/"
    c = ","
    env_names = ["test", "stage", "prod"]
}

data "template_file" "bucket_names" {
    count = 3
    template = "${element(split(local.d,
                                lookup(var.strongbox_uris,
                                       local.env_names[count.index])),
                          2)}"
}

data "template_file" "object_names" {
    count = 3
    // easier than slicing
    // replace(string, search, replace)
    template = "${replace(lookup(var.strongbox_uris, local.env_names[count.index]),
                          format("gs:%s%s%s%s",
                                 local.d,
                                 local.d,
                                 element(data.template_file.bucket_names.*.rendered, count.index),
                                 local.d),
                          "")}"
}

data "template_file" "id_csv" {
    count = 3
    template = "${join(local.c,
                       compact(distinct(split(local.c,
                                              lookup(module.env_readers.transmogrified,
                                                     local.env_names[count.index])))))}"
}

module "filter_parallel" {
    source = "../filter_parallel"
    k_csv = "${join(local.c, data.template_file.object_names.*.rendered)}"
    v_csv = "${join(local.c, data.template_file.id_csv.*.rendered)}"
    v_re = "^\\s*$"
}

// ref: https://www.terraform.io/docs/providers/google/r/storage_object_acl.html
resource "google_storage_object_acl" "strongbox_acl" {
    count = "${var.set_acls == 1
               ? module.filter_parallel.count
               : 0}"
    bucket = "${element(data.template_file.bucket_names.*.rendered, count.index)}"
    object= "${element(module.filter_parallel.keys, count.index)}"
    role_entity = ["${formatlist("READER:user-%s",
                                 split(local.c,
                                       element(module.filter_parallel.values,
                                               count.index)))}"]
}

output "object_readers" {
    value = "${zipmap(data.template_file.object_names.*.rendered,
                      data.template_file.id_csv.*.rendered)}"
    // sensitive = true
    sensitive = false
}

locals {
    unique_buckets = ["${distinct(data.template_file.bucket_names.*.rendered)}"]
}

data "template_file" "bucket_readers" {
    count = 1   // value cannot be computed: "${length(local.unique_buckets)}"
    // template_files all rendered in same order (test, stage, prod)
    // keys (second item) do not have to be unique, all are used
    template = "${join(local.c, matchkeys(data.template_file.id_csv.*.rendered,
                                          data.template_file.bucket_names.*.rendered,
                                          list(local.unique_buckets[count.index])))}"
}

data "template_file" "unique_bucket_readers" {
    count = 1  // value cannot be computed: "${length(local.unique_buckets)}"
    template = "${join(local.c,
                       distinct(compact(split(local.c,
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
    members = ["${formatlist("serviceAccount:%s",
                             split(local.c,
                                   element(data.template_file.unique_bucket_readers.*.rendered,
                                           count.index)))}"]
}

output "bucket_readers" {
    value = "${zipmap(local.unique_buckets,
                      data.template_file.unique_bucket_readers.*.rendered)}"
    // sensitive = true
    sensitive = false
}
