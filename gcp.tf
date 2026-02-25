# ===== GCP VPCs and Networks =====
resource "google_compute_network" "vpc" {
  count                   = 3
  name                    = "vpc-gcp-r${count.index + 1}"
  auto_create_subnetworks = false
  project                 = var.gcp_project
}

# ===== GCP Subnets (1 public + 2 private per VPC) =====
resource "google_compute_subnetwork" "public" {
  count         = 3
  name          = "subnet-public-r${count.index + 1}"
  ip_cidr_range = cidrsubnet(var.gcp_subnet_cidrs[count.index], 8, 1)
  region        = var.gcp_regions[count.index]
  network       = google_compute_network.vpc[count.index].id
  project       = var.gcp_project
}

resource "google_compute_subnetwork" "private" {
  count         = 6
  name          = "subnet-private-r${floor(count.index / 2) + 1}-${count.index % 2}"
  ip_cidr_range = cidrsubnet(var.gcp_subnet_cidrs[floor(count.index / 2)], 8, 2 + (count.index % 2))
  region        = var.gcp_regions[floor(count.index / 2)]
  network       = google_compute_network.vpc[floor(count.index / 2)].id
  project       = var.gcp_project
}

# ===== GCP Firewalls (Security Groups equivalent) =====
resource "google_compute_firewall" "allow_internal_ssh" {
  count   = 3
  name    = "fw-allow-ssh-r${count.index + 1}"
  network = google_compute_network.vpc[count.index].name
  project = var.gcp_project

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.gcp_subnet_cidrs[count.index]]
}

# ===== GCP Compute Instances =====
resource "google_compute_instance" "vm" {
  count        = 3
  name         = "vm-gcp-r${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "${var.gcp_regions[count.index]}-a"
  project      = var.gcp_project

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private[count.index * 2].id
  }

  metadata = {
    ssh-keys = "ubuntu:${var.admin_ssh_public_key != "" ? var.admin_ssh_public_key : tls_private_key.generated.public_key_openssh}"
  }
}

# ===== GCP VPC Peerings =====
resource "google_compute_network_peering" "r1_r2" {
  name         = "peering-r1-r2"
  network      = google_compute_network.vpc[0].self_link
  peer_network = google_compute_network.vpc[1].self_link
  project      = var.gcp_project
}

resource "google_compute_network_peering" "r2_r1" {
  name         = "peering-r2-r1"
  network      = google_compute_network.vpc[1].self_link
  peer_network = google_compute_network.vpc[0].self_link
  project      = var.gcp_project
}

resource "google_compute_network_peering" "r1_r3" {
  name         = "peering-r1-r3"
  network      = google_compute_network.vpc[0].self_link
  peer_network = google_compute_network.vpc[2].self_link
  project      = var.gcp_project
}

resource "google_compute_network_peering" "r3_r1" {
  name         = "peering-r3-r1"
  network      = google_compute_network.vpc[2].self_link
  peer_network = google_compute_network.vpc[0].self_link
  project      = var.gcp_project
}

resource "google_compute_network_peering" "r2_r3" {
  name         = "peering-r2-r3"
  network      = google_compute_network.vpc[1].self_link
  peer_network = google_compute_network.vpc[2].self_link
  project      = var.gcp_project
}

resource "google_compute_network_peering" "r3_r2" {
  name         = "peering-r3-r2"
  network      = google_compute_network.vpc[2].self_link
  peer_network = google_compute_network.vpc[1].self_link
  project      = var.gcp_project
}

# ===== GCP Routes for Peering =====
resource "google_compute_route" "r1_to_r2" {
  name             = "route-r1-to-r2"
  dest_range       = var.gcp_subnet_cidrs[1]
  network          = google_compute_network.vpc[0].name
  next_hop_peering = google_compute_network_peering.r1_r2.name
  project          = var.gcp_project
  depends_on       = [google_compute_network_peering.r1_r2]
}

resource "google_compute_route" "r2_to_r1" {
  name             = "route-r2-to-r1"
  dest_range       = var.gcp_subnet_cidrs[0]
  network          = google_compute_network.vpc[1].name
  next_hop_peering = google_compute_network_peering.r2_r1.name
  project          = var.gcp_project
  depends_on       = [google_compute_network_peering.r2_r1]
}

resource "google_compute_route" "r1_to_r3" {
  name             = "route-r1-to-r3"
  dest_range       = var.gcp_subnet_cidrs[2]
  network          = google_compute_network.vpc[0].name
  next_hop_peering = google_compute_network_peering.r1_r3.name
  project          = var.gcp_project
  depends_on       = [google_compute_network_peering.r1_r3]
}

resource "google_compute_route" "r3_to_r1" {
  name             = "route-r3-to-r1"
  dest_range       = var.gcp_subnet_cidrs[0]
  network          = google_compute_network.vpc[2].name
  next_hop_peering = google_compute_network_peering.r3_r1.name
  project          = var.gcp_project
  depends_on       = [google_compute_network_peering.r3_r1]
}

resource "google_compute_route" "r2_to_r3" {
  name             = "route-r2-to-r3"
  dest_range       = var.gcp_subnet_cidrs[2]
  network          = google_compute_network.vpc[1].name
  next_hop_peering = google_compute_network_peering.r2_r3.name
  project          = var.gcp_project
  depends_on       = [google_compute_network_peering.r2_r3]
}

resource "google_compute_route" "r3_to_r2" {
  name             = "route-r3-to-r2"
  dest_range       = var.gcp_subnet_cidrs[1]
  network          = google_compute_network.vpc[2].name
  next_hop_peering = google_compute_network_peering.r3_r2.name
  project          = var.gcp_project
  depends_on       = [google_compute_network_peering.r3_r2]
}

output "gcp_vpc_ids" {
  value = { for i in range(3) : "r${i + 1}" => google_compute_network.vpc[i].id }
}

output "gcp_vm_internal_ips" {
  value = [for i in range(3) : google_compute_instance.vm[i].network_interface[0].network_ip]
}
