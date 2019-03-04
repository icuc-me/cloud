locals {
    self = "${merge(var.STAGE_SECRETS, local._src_version)}"
}
