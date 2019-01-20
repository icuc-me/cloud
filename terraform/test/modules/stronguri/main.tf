
variable "strongbox" {
    description = "URI to strongbox bucket and file"
}

locals {
    delimiter = "/"
    components = ["${split(local.delimiter, var.strongbox)}"]
}

output "bucket" {
    value = "${local.components[2]}"
    sensitive = true
}

output "filename" {
    value = "${local.components[3]}"
    sensitive = true
}

output "filename_suffix" {
    value = "${ replace(local.components[3],"/(test-)|(stage-)|(prod-)/","") }"
    sensitive = true
}
