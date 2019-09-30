provider "google" {
  credentials = file(var.credentials_path)
  project     = var.project_id
  version     = "~> 2.7"
  region      = var.region
}

provider "google-beta" {
  credentials = file(var.credentials_path)
  project     = var.project_id
  version     = "~> 2.7.0"
  region      = var.region
}