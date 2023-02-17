data "google_client_config" "default" {}

module "vpc" {
  source              = "./modules/vpc"
  vpc_name            = "main-vpc"
  subnet_name         = "main-us-central1"
  subnet_name_proxy   = "main-us-central1-proxy"
  cidr_range          = "10.0.0.0/20"
  cidr_range_proxy    = "10.100.0.0/20"
  cidr_pods           = "172.16.0.0/16"
  cidr_services       = "172.17.0.0/16"
  gcp_region          = var.gcp_region
}

module "gke" {
  source              = "./modules/gke"
  cluster_name        = "gke-gateway-api"
  subnet_name         = module.vpc.subnet_name
  gcp_project_name    = var.gcp_project_name
  gcp_region          = var.gcp_region
  gcp_zones           = ["us-central1-a","us-central1-b","us-central1-c"]
  vpc_name            = module.vpc.vpc_name
  cidr_pods           = "pods-range"
  cidr_services       = "services-range"
  machine_type        = "g1-small"
  node_locations      = "us-central1-a,us-central1-b,us-central1-c"
  min_count           = 1
  max_count           = 3
  gateway_api_channel = "CHANNEL_STANDARD"
}
