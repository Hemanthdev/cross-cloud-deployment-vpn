# ===== OCI Virtual Cloud Networks (VCNs) =====
resource "oci_core_vcn" "vcn" {
  count          = 3
  compartment_id = var.oci_compartment_id
  cidr_block     = var.oci_vcn_cidrs[count.index]
  display_name   = "vcn-oci-r${count.index + 1}"
}

# ===== OCI Subnets (Public and Private) =====
resource "oci_core_subnet" "public" {
  count                      = 3
  compartment_id             = var.oci_compartment_id
  vcn_id                     = oci_core_vcn.vcn[count.index].id
  cidr_block                 = cidrsubnet(var.oci_vcn_cidrs[count.index], 8, 1)
  display_name               = "subnet-public-r${count.index + 1}"
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "private" {
  count                      = 6
  compartment_id             = var.oci_compartment_id
  vcn_id                     = oci_core_vcn.vcn[floor(count.index / 2)].id
  cidr_block                 = cidrsubnet(var.oci_vcn_cidrs[floor(count.index / 2)], 8, 2 + (count.index % 2))
  display_name               = "subnet-private-r${floor(count.index / 2) + 1}-${count.index % 2}"
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
}

# ===== OCI Network Security Groups =====
resource "oci_core_network_security_group" "nsg" {
  count          = 3
  compartment_id = var.oci_compartment_id
  vcn_id         = oci_core_vcn.vcn[count.index].id
  display_name   = "nsg-oci-r${count.index + 1}"
}

# ===== OCI Network Security Group Rules (Allow SSH from within VCN) =====
resource "oci_core_network_security_group_security_rules" "nsg_rules" {
  count                     = 3
  network_security_group_id = oci_core_network_security_group.nsg[count.index].id
  security_rules {
    direction = "INGRESS"
    protocol  = "6" # TCP
    source    = var.oci_vcn_cidrs[count.index]
    tcp_options {
      destination_port_range {
        min = 22
        max = 22
      }
    }
  }
}

# ===== OCI Internet Gateways =====
resource "oci_core_internet_gateway" "igw" {
  count          = 3
  compartment_id = var.oci_compartment_id
  vcn_id         = oci_core_vcn.vcn[count.index].id
  display_name   = "igw-r${count.index + 1}"
  enabled        = true
}

# ===== OCI Route Tables =====
resource "oci_core_route_table" "public_rt" {
  count          = 3
  compartment_id = var.oci_compartment_id
  vcn_id         = oci_core_vcn.vcn[count.index].id
  display_name   = "rt-public-r${count.index + 1}"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[count.index].id
  }
}

resource "oci_core_route_table" "private_rt" {
  count          = 3
  compartment_id = var.oci_compartment_id
  vcn_id         = oci_core_vcn.vcn[count.index].id
  display_name   = "rt-private-r${count.index + 1}"
}

# ===== OCI Subnet Route Table Associations =====
resource "oci_core_route_table_attachment" "public_rta" {
  count          = 3
  subnet_id      = oci_core_subnet.public[count.index].id
  route_table_id = oci_core_route_table.public_rt[count.index].id
}

resource "oci_core_route_table_attachment" "private_rta" {
  count          = 6
  subnet_id      = oci_core_subnet.private[count.index].id
  route_table_id = oci_core_route_table.private_rt[floor(count.index / 2)].id
}

# ===== OCI Primary VNic (Network Interface) =====
resource "oci_core_vnic_attachment" "vm_vnic" {
  count                  = 3
  instance_id            = oci_core_instance.vm[count.index].id
  display_name           = "vnic-r${count.index + 1}"
  subnet_id              = oci_core_subnet.private[count.index * 2].id
  nsg_ids                = [oci_core_network_security_group.nsg[count.index].id]
  skip_source_dest_check = false
}

# ===== OCI Compute Instances =====
data "oci_core_images" "ubuntu" {
  compartment_id   = var.oci_compartment_id
  display_name     = "Canonical-Ubuntu-20.04"
  operating_system = "Canonical Ubuntu"
  shape            = "VM.Standard.E3.Flex"
}

resource "oci_core_instance" "vm" {
  count               = 3
  availability_domain = data.oci_core_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.oci_compartment_id
  shape               = "VM.Standard.E3.Flex"
  display_name        = "vm-oci-r${count.index + 1}"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 1
  }

  source_details {
    source_id   = data.oci_core_images.ubuntu.images[0].id
    source_type = "IMAGE"
  }

  metadata = {
    ssh_authorized_keys = var.admin_ssh_public_key != "" ? var.admin_ssh_public_key : tls_private_key.generated.public_key_openssh
    user_data           = base64encode("#!/bin/bash\necho 'Instance initialized'")
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.private[count.index * 2].id
    nsg_ids        = [oci_core_network_security_group.nsg[count.index].id]
    hostname_label = "vm-r${count.index + 1}"
  }
}

# ===== OCI Local Peering Gateways =====
resource "oci_core_local_peering_gateway" "r1_lpg" {
  count          = 3
  compartment_id = var.oci_compartment_id
  vcn_id         = oci_core_vcn.vcn[count.index].id
  display_name   = "lpg-r${count.index + 1}"
}

# Data source for availability domains
data "oci_core_availability_domains" "ads" {
  compartment_id = var.oci_compartment_id
}

# ===== OCI Local Peering Gateway Connections =====
resource "oci_core_local_peering_gateway_peer_id_management" "r1_r2_peer" {
  local_peering_gateway_id = oci_core_local_peering_gateway.r1_lpg[0].id
  peer_id                  = oci_core_local_peering_gateway.r1_lpg[1].id
}

resource "oci_core_local_peering_gateway_peer_id_management" "r1_r3_peer" {
  local_peering_gateway_id = oci_core_local_peering_gateway.r1_lpg[0].id
  peer_id                  = oci_core_local_peering_gateway.r1_lpg[2].id
}

resource "oci_core_local_peering_gateway_peer_id_management" "r2_r3_peer" {
  local_peering_gateway_id = oci_core_local_peering_gateway.r1_lpg[1].id
  peer_id                  = oci_core_local_peering_gateway.r1_lpg[2].id
}

output "oci_vcn_ids" {
  value = { for i in range(3) : "r${i + 1}" => oci_core_vcn.vcn[i].id }
}

output "oci_vm_private_ips" {
  value = [for i in range(3) : oci_core_instance.vm[i].private_ip]
}
