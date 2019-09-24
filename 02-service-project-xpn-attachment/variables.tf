variable "organization_id" {
  description = "The organization id for the associated services"
}

variable "folder_id" {
  description = "ID of the folder wherein this project gets created"
}


variable "credentials_path" {
  description = "Path to a Service Account credentials file with permissions documented in the readme"
}

variable "host_project_name" {
  description = "Name for Shared VPC host project"
}

variable "service_project_name" {
  description = "Name for service project utilizing shared vpc host project"
}

variable "network_name" {
  description = "Name for Shared VPC network"
}

variable "billing_account" {
  description = "The ID of the billing account to associate this project with"
}

variable "shared_vpc_subnets" {
  description = "List of subnets fully qualified subnet IDs (ie. projects/$PROJECT_ID/regions/$REGION/subnetworks/$SUBNET_ID)"
  type        = list(string)
}


variable "shared_vpc" {
  description = "The ID of the host project which hosts the shared VPC"
}
