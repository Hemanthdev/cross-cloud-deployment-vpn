# ===== Azure Resource Groups and VNets =====
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "rg" {
  count    = length(var.azure_locations)
  name     = "rg-${count.index + 1}"
  location = var.azure_locations[count.index]
}

resource "azurerm_virtual_network" "vnet" {
  count               = length(var.azure_locations)
  name                = "vnet-${count.index + 1}"
  address_space       = [var.azure_vnet_cidrs[count.index]]
  location            = var.azure_locations[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
}

# ===== Azure Subnets =====
resource "azurerm_subnet" "public" {
  count                = length(var.azure_locations)
  name                 = "public"
  resource_group_name  = azurerm_resource_group.rg[count.index].name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.azure_vnet_cidrs[count.index], 8, 1)]
}

resource "azurerm_subnet" "private" {
  count                = length(var.azure_locations) * 2
  name                 = "private-${floor(count.index / 2)}-${count.index % 2}"
  resource_group_name  = azurerm_resource_group.rg[floor(count.index / 2)].name
  virtual_network_name = azurerm_virtual_network.vnet[floor(count.index / 2)].name
  address_prefixes     = [cidrsubnet(var.azure_vnet_cidrs[floor(count.index / 2)], 8, 2 + (count.index % 2))]
}

# ===== Azure Network Security Groups =====
resource "azurerm_network_security_group" "nsg" {
  count               = length(var.azure_locations)
  name                = "nsg-${count.index + 1}"
  location            = var.azure_locations[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name

  security_rule {
    name                       = "Allow-SSH-From-VNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.azure_vnet_cidrs[count.index]
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }
}

resource "azurerm_subnet_network_security_group_association" "pub_assoc" {
  count                     = length(var.azure_locations)
  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
}

# ===== Azure Route Tables =====
resource "azurerm_route_table" "rt" {
  count               = length(var.azure_locations)
  name                = "rt-${count.index + 1}"
  location            = var.azure_locations[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name
}

resource "azurerm_subnet_route_table_association" "priv_rta" {
  count          = length(var.azure_locations) * 2
  subnet_id      = azurerm_subnet.private[count.index].id
  route_table_id = azurerm_route_table.rt[floor(count.index / 2)].id
}

# ===== Azure Network Interfaces =====
resource "azurerm_network_interface" "nic" {
  count               = length(var.azure_locations)
  name                = "nic-${count.index + 1}"
  location            = var.azure_locations[count.index]
  resource_group_name = azurerm_resource_group.rg[count.index].name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.private[count.index * 2].id
    private_ip_address_allocation = "Dynamic"
  }
}

# ===== Azure VMs =====
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = length(var.azure_locations)
  name                  = "vm-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.rg[count.index].name
  location              = var.azure_locations[count.index]
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_public_key != "" ? var.admin_ssh_public_key : tls_private_key.generated.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }
}

# ===== Azure VNet Peerings =====
resource "azurerm_virtual_network_peering" "r1_to_r2" {
  name                         = "r1-to-r2"
  resource_group_name          = azurerm_resource_group.rg[0].name
  virtual_network_name         = azurerm_virtual_network.vnet[0].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[1].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "r2_to_r1" {
  name                         = "r2-to-r1"
  resource_group_name          = azurerm_resource_group.rg[1].name
  virtual_network_name         = azurerm_virtual_network.vnet[1].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "r1_to_r3" {
  name                         = "r1-to-r3"
  resource_group_name          = azurerm_resource_group.rg[0].name
  virtual_network_name         = azurerm_virtual_network.vnet[0].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[2].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "r3_to_r1" {
  name                         = "r3-to-r1"
  resource_group_name          = azurerm_resource_group.rg[2].name
  virtual_network_name         = azurerm_virtual_network.vnet[2].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "r2_to_r3" {
  name                         = "r2-to-r3"
  resource_group_name          = azurerm_resource_group.rg[1].name
  virtual_network_name         = azurerm_virtual_network.vnet[1].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[2].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "r3_to_r2" {
  name                         = "r3-to-r2"
  resource_group_name          = azurerm_resource_group.rg[2].name
  virtual_network_name         = azurerm_virtual_network.vnet[2].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[1].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

output "azure_vnet_ids" {
  value = { for i in range(length(var.azure_locations)) : "r${i + 1}" => azurerm_virtual_network.vnet[i].id }
}

output "azure_vm_private_ips" {
  value = [for i in range(length(var.azure_locations)) : azurerm_network_interface.nic[i].private_ip_address]
}
