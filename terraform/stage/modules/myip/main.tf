
data "external" "myip" {
    program = ["${path.module}/myip.py"]
}

output "ip" {
    value = "${data.external.myip.result.ip}"
    sensitive = true
}
