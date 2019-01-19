
module "test_service_account" {
    source = "./modules/service_account"
    providers {
        google = "google.test"
    }
    susername = "${var.TEST_SECRETS["SUSERNAME"]}"
}

/* NOT SUPPORTED IN TEST */
module "stage_service_account" {
    source = "./modules/service_account"
    providers {
        google = "google.stage"
    }
    susername = "${var.STAGE_SECRETS["SUSERNAME"]}"
}

/* NOT SUPPORTED IN TEST OR STAGE
module "prod_service_account" {
    source = "./modules/service_account"
    providers {
        google = "google.prod"
    }
    susername = "${var.PROD_SECRETS["SUSERNAME"]}"
}
NOT SUPPORTED IN TEST OR STAGE */
