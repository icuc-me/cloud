/* NEEDS PER-ENV MODIFICATION */

/**** TEST ****/
module "test_service_account" {
    source = "./modules/service_account"
    providers { google = "google.test" }
    env_name = "${var.ENV_NAME}"
    susername = "${var.TEST_SECRETS["SUSERNAME"]}"
    create = "${local.is_prod}"
}

output "test_service_account" {
    value = "${module.test_service_account.email}"
    sensitive = true
}

/**** STAGE ****/
// module "stage_service_account" {
//     source = "./modules/service_account"
//     providers { google = "google.stage" }
//     env_name = "${var.ENV_NAME}"
//     susername = "${var.STAGE_SECRETS["SUSERNAME"]}"
//     create = "${local.is_prod}"
// }
//
// output "stage_service_account" {
//     value = "${module.stage_service_account.email}"
//     sensitive = true
// }

/**** PROD ****/
// module "prod_service_account" {
//     source = "./modules/service_account"
//     providers { google = "google.prod" }
//     env_name = "${var.ENV_NAME}"
//     susername = "${var.PROD_SECRETS["SUSERNAME"]}"
//     create = "${local.is_prod}"
// }
//
// output "prod_service_account" {
//     value = "${module.prod_service_account.email}"
//     sensitive = true
// }

output "uuid" {
    value = "${var.UUID}"
    sensitive = true
}
