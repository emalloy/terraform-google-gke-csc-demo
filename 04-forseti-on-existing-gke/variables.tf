/**
 * Copyright 2019 Google LLC
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

variable "credentials_path" {
  description = "Path to service account json"
}

variable "config_validator_enabled" {
  description = "Config Validator scanner enabled."
  type        = bool
  default     = false
}

variable "domain" {
  description = "The domain associated with the GCP Organization ID"
}

variable "git_sync_image" {
  description = "The container image used by the config-validator git-sync side-car"
  default     = "gcr.io/google-containers/git-sync"
}

variable "git_sync_image_tag" {
  description = "The container image tag used by the config-validator git-sync side-car"
  default     = "v3.1.2"
}

variable "git_sync_private_ssh_key_file" {
  description = "The file containing the private SSH key allowing the git-sync to clone the policy library repository."
  default     = ""
}

variable "git_sync_ssh" {
  description = "Use SSH for git-sync operations"
  type        = bool
  default     = false
}

variable "git_sync_wait" {
  description = "The time number of seconds between git-syncs"
  default     = 30
}

// existing

variable "gke_cluster_ca_cert" {
  description = "base64 encoded gke cluster client ca cert"
  default     = ""
}
variable "gke_client_access_token" {
  description = "base64 encoded gke cluster client access token"
  default     = ""
}

variable "gke_endpoint" {
  description = "ipaddr or hostname of existing gke endpoint"
  default     = ""
}

variable "gke_cluster_name" {
  description = "name of the existing gke cluster"
}

variable "gke_cluster_location" {
  description = "location - region where the existing gke cluster located"
}


variable "gke_service_account" {
  description = "The service account to run nodes as if not overridden in node_pools. The default value will cause a cluster-specific service account to be created."
  default     = "create"
}


variable "network_project_id" {
  description = "project id of the host xpn network project"
}

variable "suffix" {
  description = "descriptive suffix"
  default = ""
}


variable "gke_service_ip_range" {
  description = "The IP range of the Kubernetes services."
  default     = "10.3.0.0/20"
}

variable "gsuite_admin_email" {
  description = "G-Suite administrator email address to manage your Forseti installation"
}

variable "helm_repository_url" {
  description = "The Helm repository containing the 'forseti-security' Helm charts"
  default     = "https://forseti-security-charts.storage.googleapis.com/release/"
}

variable "k8s_config_validator_image" {
  description = "The container image used by the config-validator"
  default     = "gcr.io/forseti-containers/config-validator"
}

variable "k8s_config_validator_image_tag" {
  description = "The tag for the config-validator image."
  default     = "latest"
}

variable "k8s_forseti_namespace" {
  description = "The Kubernetes namespace in which to deploy Forseti."
  default     = "forseti"
}

variable "k8s_forseti_orchestrator_image" {
  description = "The container image for the Forseti orchestrator"
  default     = "gcr.io/forseti-containers/forseti"
}

variable "k8s_forseti_orchestrator_image_tag" {
  description = "The tag for the container image for the Forseti orchestrator"
  default     = "v2.21.0"
}

variable "k8s_forseti_server_image" {
  description = "The container image for the Forseti server"
  default     = "gcr.io/forseti-containers/forseti"
}

variable "k8s_forseti_server_image_tag" {
  description = "The tag for the container image for the Forseti server"
  default     = "v2.21.0"
}

variable "k8s_tiller_sa_name" {
  description = "The Kubernetes Service Account used by Tiller"
  default     = "tiller"
}

variable "load_balancer" {
  description = "The type of load balancer to deploy for the forseti-server if desired: none, external, internal"
  default     = "internal"
}

variable "network" {
  description = "Name of network to deploy forseti assets"
  default     = "forseti-gke-network"
}

variable "production" {
  description = "Whether or not to deploy Forseti on GKE in a production configuration"
  type        = bool
  default     = true
}

variable "org_id" {
  description = "GCP Organization ID that Forseti will have purview over"
}

variable "policy_library_repository_url" {
  description = "The git repository containing the policy-library."
  default     = "https://github.com/forseti-security/policy-library"
}

variable "policy_library_repository_branch" {
  description = "The specific git branch containing the policies."
  default     = "master"
}

variable "project_id" {
  description = "The ID of an existing Google project where Forseti will be installed"
}

variable "region" {
  description = "Region where forseti subnetwork will be deployed"
  default     = "us-central1"
}

variable "sub_network_name" {
  description = "The name of the subnet being created"
  default     = "gke-sub-network"
}


variable "server_log_level" {
  description = "The log level of the Forseti server container."
  default     = "info"
}
