locals {
  region           = "asia-southeast1"
  network_name     = "media-wiki-vpc"
  subnetwork_name  = "media-wiki-subnet"
  project          = "mediawiki-us-prj"
  secondary_ip_ranges = {
    "pod-ip-range"      = "20.0.0.0/16",
    "services-ip-range" = "20.4.0.0/19"
  }
}


resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "container" {
  service = "container.googleapis.com"
}


resource "google_compute_network" "network" {
  name                      = local.network_name 
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
   depends_on = [
    google_project_service.compute,
    google_project_service.container
  ]
}

resource "google_compute_subnetwork" "subnetwork" {
  name                     = local.subnetwork_name 
  ip_cidr_range            = "10.0.0.0/16"
  region                   = local.region 
  network                  = google_compute_network.network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.10.0.0/16"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.20.0.0/16"
  }
}

resource "google_container_cluster" "gke" {
  name                     = "media-wiki-gke"
  location                 = "asia-southeast1" 
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.network.self_link
  subnetwork               = google_compute_subnetwork.subnetwork.self_link
  
 

 ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }


}

resource "google_container_node_pool" "node" {
  name       = "general"
  cluster    = google_container_cluster.gke.id
  node_count = 1

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  
}