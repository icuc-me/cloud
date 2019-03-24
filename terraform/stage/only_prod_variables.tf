locals {
    self = "${merge(var.PROD_SECRETS, local._src_version)}"
}
