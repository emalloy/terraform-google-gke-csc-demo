/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
  this is the skeleton scaffold for a host and service project
  host project, containing the vpc, subnets and routes and
  xpn declaration which explicitly shares the four subnets individually
  to the service project which has the permissions to utilize this network
  and named subnets.
*/

locals {
  credentials_file_path = var.credentials_path
  subnet_01             = "${var.network_name}-subnet-01"
  subnet_01_secondary        = ["10.15.0.0/16","10.16.0.0/16"]
  subnet_02             = "${var.network_name}-subnet-02"
  subnet_02_secondary        = ["10.17.0.0/16","10.18.0.0/16"]
  subnet_03             = "${var.network_name}-subnet-03"
  subnet_03_secondary        = ["10.19.0.0/16","10.20.0.0/16"]
  subnet_04             = "${var.network_name}-subnet-04"
   subnet_04_secondary        = ["10.21.0.0/16","10.22.0.0/16"]

}

/******************************************
  Provider configuration
 *****************************************/
provider "google" {
  credentials = file(local.credentials_file_path)
  version     = "~> 2.7.0"
}

provider "google-beta" {
  credentials = file(local.credentials_file_path)
  version     = "~> 2.7.0"
}

/******************************************
  Host Project Creation
 *****************************************/
module "host-project" {
  source            = "git::https://github.com/terraform-google-modules/terraform-google-project-factory.git?ref=master"
  random_project_id = true
  name              = var.host_project_name
  org_id            = var.organization_id
  billing_account   = var.billing_account
  credentials_path  = local.credentials_file_path
  folder_id         = var.folder_id
  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudbilling.googleapis.com",
    "sqladmin.googleapis.com",
    "serviceusage.googleapis.com",
    "securitycenter.googleapis.com",
    "dlp.googleapis.com",
    "servicenetworking.googleapis.com",
  ]

}

/******************************************
  Network Creation
 *****************************************/
module "vpc" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-network.git?ref=master"

  project_id   = module.host-project.project_id
  network_name = var.network_name

  delete_default_internet_gateway_routes = false
  shared_vpc_host                        = true

  subnets = [
    {
      subnet_name           = local.subnet_01
      subnet_ip             = "10.10.0.0/16"
      subnet_region         = "us-west1"
      subnet_private_access = "true"
    },
    {
      subnet_name           = local.subnet_02
      subnet_ip             = "10.11.0.0/16"
      subnet_region         = "us-west1"
      subnet_private_access = true
      subnet_flow_logs      = true
    },
    {
      subnet_name           = local.subnet_03
      subnet_ip             = "10.12.0.0/16"
      subnet_region         = "us-west1"
      subnet_private_access = true
      subnet_flow_logs      = true
    },
    {
      subnet_name           = local.subnet_04
      subnet_ip             = "10.13.0.0/16"
      subnet_region         = "us-west1"
      subnet_private_access = true
      subnet_flow_logs      = true
    },
  ]

  secondary_ranges = {
    "${local.subnet_01}" = [
      {
        range_name    = "${local.subnet_01}-01"
        ip_cidr_range = "${local.subnet_01_secondary[0]}"
      },
      {
        range_name    = "${local.subnet_01}-02"
        ip_cidr_range = "${local.subnet_01_secondary[1]}"
      },
    ]
    "${local.subnet_02}" = [
      {
        range_name    = "${local.subnet_02}-01"
        ip_cidr_range = "${local.subnet_02_secondary[0]}"
      },
      {
        range_name    = "${local.subnet_02}-02"
        ip_cidr_range = "${local.subnet_02_secondary[1]}"
      },
    ]
    "${local.subnet_03}" = [
      {
        range_name    = "${local.subnet_03}-01"
        ip_cidr_range = "${local.subnet_03_secondary[0]}"
      },
      {
        range_name    = "${local.subnet_03}-02"
        ip_cidr_range = "${local.subnet_03_secondary[1]}"
      },
    ]
    "${local.subnet_04}" = [
      {
        range_name    = "${local.subnet_04}-01"
        ip_cidr_range = "${local.subnet_04_secondary[0]}"
      },
      {
        range_name    = "${local.subnet_04}-02"
        ip_cidr_range = "${local.subnet_04_secondary[1]}"
      },
    ]
  }

  // public route
  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
  ]
}


// cloud router

resource "google_compute_router" "router-us-west1" {
  name    = "us-west1-router"
  region  = "us-west1"
  network = module.vpc.network_name
  project = module.host-project.project_id
}


// cloud nat

module "cloud-nat" {
  source     = "git::https://github.com/terraform-google-modules/terraform-google-cloud-nat.git?ref=83b1cf27a62cb91f9030b1ffb39b35450c637712"
  router     = google_compute_router.router-us-west1.name
  project_id = module.host-project.project_id
  region     = "us-west1"
  name       = "nat-us-west1"
}

// @todo - less permissive :)
module "firewall-preseed" {
  source                  = "git::https://github.com/terraform-google-modules/terraform-google-network.git//modules/fabric-net-firewall?ref=master"
  project_id              = module.host-project.project_id
  network                 = module.vpc.network_name
  internal_ranges_enabled = true
  internal_ranges         = module.vpc.subnets_ips

  internal_allow = [{
    protocol = "icmp"
    },
    {
      protocol = "tcp"
    },
    {
      protocol = "udp"
    },
  ]
}


resource "google_compute_firewall" "allow-tag-sql" {
  count         = length(module.vpc.subnets_ips) > 0 ? 1 : 0
  name          = "${module.vpc.network_name}-ingress-tag-sql"
  description   = "Allow SQL to machines with the 'sql' tag"
  network       = module.vpc.network_name
  project       = module.host-project.project_id
  source_ranges = concat(module.vpc.subnets_ips,local.subnet_04_secondary)
  target_tags   = ["sql"]

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
}

resource "google_compute_firewall" "allow-tag-sql-replication" {
  count         = length(module.vpc.subnets_ips) > 0 ? 1 : 0
  name          = "${module.vpc.network_name}-ingress-tag-sql-replication"
  description   = "Allow SQL Replication to machines with the 'sql-replication' tag"
  network       = module.vpc.network_name
  project       = module.host-project.project_id
  source_ranges = module.vpc.subnets_ips
  target_tags   = ["sql-replication"]
  allow {
    protocol = "tcp"
    ports = ["4444",
      "4567",
    "4568"]
  }
}
