/*
 GKE project with xpn network establishment
*/



locals {
  credentials_file_path = var.credentials_path
}


module "project-factory" {
  source            = "git::https://github.com/terraform-google-modules/terraform-google-project-factory.git?ref=master"
  random_project_id = true
  name              = var.service_project_name
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  shared_vpc = "${var.shared_vpc}"
  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudbilling.googleapis.com",
    "sqladmin.googleapis.com",
    "serviceusage.googleapis.com",
    "securitycenter.googleapis.com",
    "dlp.googleapis.com",
  ]
  credentials_path = local.credentials_file_path

  shared_vpc_subnets = "${var.shared_vpc_subnets}"

}
