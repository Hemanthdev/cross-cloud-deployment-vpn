# ===== Multi-Cloud VPN Configuration =====
# This file configures VPN gateways in each cloud and establishes cross-cloud connectivity

# ===== AWS VPN Gateway =====
resource "aws_vpn_gateway" "vpn_gw" {
  count  = var.vpn_enabled ? 1 : 0
  vpc_id = aws_vpc.r1.id

  tags = {
    Name = "aws-vpn-gateway"
  }
}

resource "aws_vpn_gateway_attachment" "vpn_gw_r2" {
  count          = var.vpn_enabled ? 1 : 0
  vpc_id         = aws_vpc.r2.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gw[0].id
  provider       = aws.r2
}

resource "aws_vpn_gateway_attachment" "vpn_gw_r3" {
  count          = var.vpn_enabled ? 1 : 0
  vpc_id         = aws_vpc.r3.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gw[0].id
  provider       = aws.r3
}

resource "aws_customer_gateway" "azure_cgw" {
  count     = var.vpn_enabled ? 1 : 0
  bgp_asn   = 65000
  public_ip = azure_public_ip.vpn_gateway_pip[0].ip_address
  type      = "ipsec.1"

  tags = {
    Name = "azure-customer-gateway"
  }
}

resource "aws_vpn_connection" "to_azure" {
  count               = var.vpn_enabled ? 1 : 0
  type                = "ipsec.1"
  customer_gateway_id = aws_customer_gateway.azure_cgw[0].id
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw[0].id
  static_routes_only  = true

  tags = {
    Name = "aws-to-azure-vpn"
  }
}

resource "aws_vpn_connection_route" "azure_subnet_routes" {
  count                  = var.vpn_enabled ? 1 : 0
  destination_cidr_block = var.azure_vnet_cidrs[0]
  vpn_connection_id      = aws_vpn_connection.to_azure[0].id
}

resource "aws_vpn_gateway_route_propagation" "r1_public_rt" {
  count          = var.vpn_enabled ? 1 : 0
  vpn_gateway_id = aws_vpn_gateway.vpn_gw[0].id
  route_table_id = aws_route_table.r1_public_rt.id
}

resource "aws_vpn_gateway_route_propagation" "r1_private_rt" {
  count          = var.vpn_enabled ? 1 : 0
  vpn_gateway_id = aws_vpn_gateway.vpn_gw[0].id
  route_table_id = aws_route_table.r1_private_rt.id
}

# ===== Azure VPN Gateway =====
resource "azurerm_public_ip" "vpn_gateway_pip" {
  count               = var.vpn_enabled ? 1 : 0
  name                = "pip-vpn-gateway"
  location            = var.azure_locations[0]
  resource_group_name = azurerm_resource_group.rg[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.vpn_enabled ? 1 : 0
  name                = "vpn-gateway"
  location            = var.azure_locations[0]
  resource_group_name = azurerm_resource_group.rg[0].name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_pip[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.public[0].id
  }
}

resource "azurerm_local_network_gateway" "aws_local_gw" {
  count               = var.vpn_enabled ? 1 : 0
  name                = "aws-local-gateway"
  location            = var.azure_locations[0]
  resource_group_name = azurerm_resource_group.rg[0].name
  gateway_address     = aws_vpn_connection.to_azure[0].customer_gateway_address
  address_space       = var.aws_vpc_cidrs
}

resource "azurerm_virtual_network_gateway_connection" "to_aws" {
  count                      = var.vpn_enabled ? 1 : 0
  name                       = "azure-to-aws-vpn"
  location                   = var.azure_locations[0]
  resource_group_name        = azurerm_resource_group.rg[0].name
  type                       = "IPSec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_local_gw[0].id
  shared_key                 = var.vpn_preshared_key
}

# ===== GCP Cloud VPN =====
resource "google_compute_vpn_gateway" "vpn_gateway" {
  count   = var.vpn_enabled ? 1 : 0
  name    = "vpn-gateway-gcp"
  network = google_compute_network.vpc[0].id
  region  = var.gcp_regions[0]
  project = var.gcp_project
}

resource "google_compute_forwarding_rule" "esp" {
  count                 = var.vpn_enabled ? 1 : 0
  name                  = "vpn-forwarding-rule-esp"
  ip_protocol           = "ESP"
  ip_version            = "IPV4"
  load_balancing_scheme = "EXTERNAL"
  network_tier          = "PREMIUM"
  region                = var.gcp_regions[0]
  project               = var.gcp_project
  target                = google_compute_vpn_gateway.vpn_gateway[0].self_link
}

resource "google_compute_forwarding_rule" "udp500" {
  count                 = var.vpn_enabled ? 1 : 0
  name                  = "vpn-forwarding-rule-udp500"
  ip_protocol           = "UDP"
  load_balancing_scheme = "EXTERNAL"
  network_tier          = "PREMIUM"
  port_range            = "500"
  region                = var.gcp_regions[0]
  project               = var.gcp_project
  target                = google_compute_vpn_gateway.vpn_gateway[0].self_link
}

resource "google_compute_forwarding_rule" "udp4500" {
  count                 = var.vpn_enabled ? 1 : 0
  name                  = "vpn-forwarding-rule-udp4500"
  ip_protocol           = "UDP"
  load_balancing_scheme = "EXTERNAL"
  network_tier          = "PREMIUM"
  port_range            = "4500"
  region                = var.gcp_regions[0]
  project               = var.gcp_project
  target                = google_compute_vpn_gateway.vpn_gateway[0].self_link
}

resource "google_compute_vpn_tunnel" "tunnel_to_aws" {
  count                   = var.vpn_enabled ? 1 : 0
  name                    = "vpn-tunnel-gcp-aws"
  vpn_gateway             = google_compute_vpn_gateway.vpn_gateway[0].self_link
  peer_ip                 = aws_vpn_connection.to_azure[0].tunnel1_address
  shared_secret           = var.vpn_preshared_key
  ike_version             = 2
  region                  = var.gcp_regions[0]
  project                 = var.gcp_project
  target_vpn_gateway      = google_compute_vpn_gateway.vpn_gateway[0].self_link
  remote_traffic_selector = [var.aws_vpc_cidrs[0]]
}

resource "google_compute_route" "route_to_aws" {
  count               = var.vpn_enabled ? 1 : 0
  name                = "route-gcp-to-aws"
  dest_range          = var.aws_vpc_cidrs[0]
  network             = google_compute_network.vpc[0].name
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel_to_aws[0].self_link
  project             = var.gcp_project
}

# ===== OCI Site-to-Site VPN =====
resource "oci_core_drg" "drg" {
  count          = var.vpn_enabled ? 1 : 0
  compartment_id = var.oci_compartment_id
  display_name   = "dynamic-routing-gateway"
}

resource "oci_core_drg_attachment" "vcn_attachment" {
  count        = var.vpn_enabled ? 3 : 0
  drg_id       = oci_core_drg.drg[0].id
  vcn_id       = oci_core_vcn.vcn[count.index].id
  display_name = "vcn-drg-attachment-${count.index + 1}"
}

resource "oci_core_ip_sec_connection" "vpn_to_aws" {
  count          = var.vpn_enabled ? 1 : 0
  compartment_id = var.oci_compartment_id
  cpe_id         = oci_core_cpe.aws_cpe[0].id
  drg_id         = oci_core_drg.drg[0].id
  static_routes  = [var.aws_vpc_cidrs[0]]
  display_name   = "ipsec-to-aws"
}

resource "oci_core_cpe" "aws_cpe" {
  count          = var.vpn_enabled ? 1 : 0
  compartment_id = var.oci_compartment_id
  ip_address     = aws_vpn_connection.to_azure[0].tunnel1_address
  display_name   = "aws-customer-premises-equipment"
}

# ===== VPN Connection Outputs =====
output "aws_vpn_gateway_id" {
  value       = var.vpn_enabled ? aws_vpn_gateway.vpn_gw[0].id : null
  description = "AWS VPN Gateway ID"
}

output "azure_vpn_gateway_id" {
  value       = var.vpn_enabled ? azurerm_virtual_network_gateway.vpn[0].id : null
  description = "Azure VPN Gateway ID"
}

output "gcp_vpn_gateway_id" {
  value       = var.vpn_enabled ? google_compute_vpn_gateway.vpn_gateway[0].id : null
  description = "GCP VPN Gateway ID"
}

output "oci_drg_id" {
  value       = var.vpn_enabled ? oci_core_drg.drg[0].id : null
  description = "OCI Dynamic Routing Gateway ID"
}

output "vpn_connection_status" {
  value       = var.vpn_enabled ? "VPN connections established between AWS, Azure, GCP, and OCI" : "VPN disabled"
  description = "Multi-cloud VPN connectivity status"
}
