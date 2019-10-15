variable "credentials_path" {
  description = "Path to service account json"
}


variable "project_id" {
  description = "target project"
}

variable "host_project_id" {
  description = "xpn project id"
}

variable "subnetwork" {
  description = "subnet name target"
}

variable "region" {
  description = "region"
}
variable "startup_script" {
  description = "path to startup script to attach to instance template"
}

variable "static_ips" {
  description = "specify the static ip members of the galera cluster to be created"
}

variable "cluster_name" {
  description = "cluster_name"
}
