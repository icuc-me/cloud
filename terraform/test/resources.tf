
// ref: https://www.terraform.io/docs/providers/google/r/compute_address.html
resource "google_compute_address" "gateway-external" {
    name = "gateway-external-${var.env_uuid}-${count.index}"
    address_type = "EXTERNAL"
    description = "Static external address #${count.index + 1} for gateway into VPC"
    network_tier = "${var.env_name != "prod" ? "STANDARD" : "PREMIUM"}"
    count = "${var.env_name == "prod" ? 1 : 0}"  // save some money
}

resource "google_compute_address" "gateway-internal" {
    name = "gateway-internal-${var.env_uuid}-${count.index}"
    address_type = "INTERNAL"
    description = "Static internal address #${count.index + 1} for the gateway out of VPC"
}
