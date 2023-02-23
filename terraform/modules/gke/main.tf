// gke module
data "google_client_config" "default" {}

resource "google_service_account" "gke-sa" {
  account_id   = "tf-gke-sa"
  display_name = "Service Account For GKE ${var.cluster_name}"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "artifactregistry-role" {
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke-sa.email}"
  project = var.gcp_project_id
}

resource "google_project_iam_member" "node-service-account-role" {
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke-sa.email}"
  project = var.gcp_project_id
}

resource "google_service_account" "cc-sa" {
  account_id   = "tf-cc-sa"
  display_name = "Service Account For Config Connector for GKE ${var.cluster_name}"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "cc-editor-role" {
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.cc-sa.email}"
  project = var.gcp_project_id
}

resource "google_service_account_iam_binding" "cc-admin-account-iam" {
  service_account_id = google_service_account.cc-sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[cnrm-system/cnrm-controller-manager]",
  ]
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.gcp_project_id
  name                       = var.cluster_name
  region                     = var.gcp_region
  regional                   = false
  zones                      = var.gcp_zones
  network                    = var.vpc_name
  subnetwork                 = var.subnet_name
  ip_range_pods              = var.cidr_pods
  ip_range_services          = var.cidr_services
  http_load_balancing        = true
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  enable_cost_allocation     = true
  gateway_api_channel        = var.gateway_api_channel
  create_service_account     = false
  release_channel            = "REGULAR"
  remove_default_node_pool   = true
  node_metadata              = "GKE_METADATA"

  node_pools = [
    {
      name                    = "default-node-pool"
      machine_type            = var.machine_type
      node_locations          = var.node_locations
      min_count               = var.min_count
      max_count               = var.max_count
      local_ssd_count         = 0
      spot                    = false
      disk_size_gb            = 100
      disk_type               = "pd-standard"
      image_type              = "COS_CONTAINERD"
      enable_gcfs             = false
      enable_gvnic            = false
      auto_repair             = true
      auto_upgrade            = true
      preemptible             = false
      initial_node_count      = 1
      service_account         = google_service_account.gke-sa.email
      config_connector_config = false
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "${var.cluster_name}-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }

}
