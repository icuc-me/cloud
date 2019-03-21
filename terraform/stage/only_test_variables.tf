locals {
    self = "${merge(var.TEST_SECRETS, local._src_version)}"
}
