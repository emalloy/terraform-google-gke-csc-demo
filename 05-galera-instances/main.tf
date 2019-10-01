// galera gce instances


// instance service account
/* intended for stackdriver logging and monitoring agent, see :
  https://cloud.google.com/logging/docs/access-control
  https://cloud.google.com/monitoring/access-control
*/

module "service_accounts" {
  source     = "git::https://github.com/terraform-google-modules/terraform-google-service-accounts.git?ref=v2.0.1"
  project_id = "${var.project_id}"
  prefix     = "galera-sa"
  names      = ["single-account"]
  project_roles = [
    "${var.project_id}=>roles/iam.serviceAccountUser",
    "${var.project_id}=>roles/viewer",
    "${var.project_id}=>roles/storage.objectViewer",
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.host_project_id}=>roles/compute.networkUser",
  ]
}



module "instance_template" {
  source             = "git::https://github.com/terraform-google-modules/terraform-google-vm.git//modules/instance_template?ref=70949e5dcc70a5d06baf04f4aefc9704420656b1"
  project_id         = var.project_id
  subnetwork         = var.subnetwork
  subnetwork_project = var.host_project_id
  can_ip_forward     = false
  preemptible        = false
  service_account = {
    email = module.service_accounts.email
    scopes = [
      "userinfo-email",
      "compute-ro",
      "cloud-platform",
    "storage-ro"]
  }
  name_prefix          = "galera"
  machine_type         = "n1-standard-2"
  source_image_project = "debian-cloud"
  source_image_family  = "debian-9"
  tags = [
    "ssh",
    "sql",
    "sql-replication",
  ]
  disk_size_gb = 100
  disk_type    = "pd-ssd"
  auto_delete  = false
  additional_disks = [
    {
      disk_size_gb = 100
      disk_type    = "pd-standard"
      auto_delete  = "false"
      boot         = "false"
    }
  ]
  startup_script = "${file(var.startup_script)}"
}

module "compute_instance" {
  source     = "git::https://github.com/terraform-google-modules/terraform-google-vm.git//modules/compute_instance?ref=70949e5dcc70a5d06baf04f4aefc9704420656b1"
  subnetwork = var.subnetwork

  num_instances     = 1
  hostname          = "galera"
  instance_template = module.instance_template.self_link

}
