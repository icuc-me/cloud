
variable "strongbox_uri" {
    description = "URI to strongbox, including bucket, path and file."
}

variable "strongkey" {
    description = "Decryption key for contents."
}

variable "credentials" {
    description = "Path to GCE Storage credentials file"
}


data "external" "strongbox" {
    program = ["env", "${path.module}/strongbox.py"]
    query = {
        credentials = "${var.credentials}"
        strongbox = "${var.strongbox_uri}"
        strongkey = "${var.strongkey}"
    }
}

output "contents" {
    value = "${data.external.strongbox.result}"
    sensitive = true
}
