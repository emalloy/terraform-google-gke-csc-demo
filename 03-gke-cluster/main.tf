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

locals {
  cluster_type          = "shared-vpc"
  credentials_file_path = var.credentials_path
}

provider "google" {
  version     = "~> 2.12.0"
  region      = var.region
  credentials = file(local.credentials_file_path)
}

provider "google-beta" {
  credentials = file(local.credentials_file_path)
  version     = "~> 2.7.0"
}

module "gke" {
  source                 = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git?ref=master"
  project_id             = var.project_id
  name                   = "${local.cluster_type}-cluster-${var.region}-${var.cluster_name_suffix}"
  region                 = var.region
  regional               = false
  zones                  = var.zones
  network                = var.network
  network_project_id     = var.network_project_id
  subnetwork             = var.subnetwork
  ip_range_pods          = var.ip_range_pods
  ip_range_services      = var.ip_range_services
  create_service_account = true
  service_account        = "create"
  initial_node_count     = "1"



  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 1
      max_count          = 4
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      initial_node_count = 1
    },
  ]
}

data "google_client_config" "default" {
}
