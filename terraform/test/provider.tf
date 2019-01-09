provider "google" {
    credentials = "${var.TEST_SECRETS["CREDENTIALS"]}"
    project = "${var.TEST_SECRETS["PROJECT"]}"
    region = "${var.TEST_SECRETS["REGION"]}"
    zone = "${var.TEST_SECRETS["ZONE"]}"
}
