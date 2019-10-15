provider "google" {
  credentials = file(var.credentials_path)
  version     = "~> 2.11.0"
}

provider "google-beta" {
  credentials = file(var.credentials_path)
  version     = "~> 2.11.0"
  project     = var.project_id
}

provider "local" {
  version = "~> 1.3"
}

provider "null" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 2.0"
}

provider "random" {
  version = "~> 2.0"
}


// forseti

module "forseti" {
  source                      = "git::https://github.com/forseti-security/terraform-google-forseti.git?ref=v4.2.0"
  gsuite_admin_email          = "${var.gsuite_admin_email}"
  config_validator_enabled    = "${var.config_validator_enabled}"
  domain                      = "${var.domain}"
  project_id                  = "${var.project_id}"
  policy_library_sync_enabled = "${var.config_validator_enabled}"
  org_id                      = "${var.org_id}"
  network                     = "${var.network}"
  network_project             = "${var.network_project_id}"
  subnetwork                  = "${var.sub_network_name}"
  storage_bucket_location     = "${var.region}"
  server_region               = "${var.region}"
  client_region               = "${var.region}"
  cloudsql_region             = "${var.region}"
  cloudsql_private            = false
}


//*****************************************
//  Setup the Kubernetes Provider
//*****************************************

data "google_client_config" "default" {}

data "google_container_cluster" "existing_cluster" {
  name     = "${var.gke_cluster_name}"
  location = "${var.gke_cluster_location}"
  project  = "${var.project_id}"
}

provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${data.google_container_cluster.existing_cluster.endpoint}"
  token                  = "${data.google_client_config.default.access_token}"
  cluster_ca_certificate = "${base64decode(data.google_container_cluster.existing_cluster.master_auth.0.cluster_ca_certificate)}"
}

//*****************************************
//  Setup Helm Provider
//*****************************************
provider "helm" {
  version         = "~> 0.10.0"
  service_account = "${kubernetes_service_account.tiller.metadata.0.name}"
  namespace       = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  kubernetes {
    load_config_file       = false
    host                   = "https://${data.google_container_cluster.existing_cluster.endpoint}"
    token                  = "${data.google_client_config.default.access_token}"
    cluster_ca_certificate = "${base64decode(data.google_container_cluster.existing_cluster.master_auth.0.cluster_ca_certificate)}"
  }
  debug                           = true
  automount_service_account_token = true
  install_tiller                  = true
}


resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "terraform-tiller"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "terraform-tiller"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind = "ServiceAccount"
    name = "terraform-tiller"

    api_group = ""
    namespace = "kube-system"
  }

}

//*****************************************
//  Deploy Forseti on GKE
//*****************************************

module "forseti-on-gke" {
  source                   = "git::https://github.com/forseti-security/terraform-google-forseti.git//modules/on_gke?ref=v4.2.0"
  config_validator_enabled = "${var.config_validator_enabled}"

  forseti_client_service_account     = "${module.forseti.forseti-client-service-account}"
  forseti_client_vm_ip               = "${module.forseti.forseti-client-vm-ip}"
  forseti_cloudsql_connection_name   = "${module.forseti.forseti-cloudsql-connection-name}"
  forseti_server_service_account     = "${module.forseti.forseti-server-service-account}"
  forseti_server_bucket              = "${module.forseti.forseti-server-storage-bucket}"
  git_sync_image                     = "${var.git_sync_image}"
  git_sync_image_tag                 = "${var.git_sync_image_tag}"
  git_sync_private_ssh_key_file      = "${var.git_sync_private_ssh_key_file}"
  git_sync_ssh                       = "${var.git_sync_ssh}"
  git_sync_wait                      = "${var.git_sync_ssh}"
  gke_service_account                = "${var.gke_service_account}"
  k8s_config_validator_image         = "${var.k8s_config_validator_image}"
  k8s_config_validator_image_tag     = "${var.k8s_config_validator_image_tag}"
  k8s_forseti_namespace              = "${var.k8s_forseti_namespace}"
  k8s_forseti_orchestrator_image     = "${var.k8s_forseti_orchestrator_image}"
  k8s_forseti_orchestrator_image_tag = "${var.k8s_forseti_orchestrator_image_tag}"
  k8s_forseti_server_image           = "${var.k8s_forseti_server_image}"
  k8s_forseti_server_image_tag       = "${var.k8s_forseti_server_image_tag}"
  helm_repository_url                = "${var.helm_repository_url}"
  policy_library_repository_url      = "${var.policy_library_repository_url}"
  project_id                         = "${var.project_id}"
  load_balancer                      = "${var.load_balancer}"
  server_log_level                   = "${var.server_log_level}"
}
