variable "aws_regions" {
  description = "List of AWS regions to create VPCs in"
  type        = list(string)
  default     = ["us-west-2", "us-west-1", "us-east-1"]
}

variable "aws_vpc_cidrs" {
  description = "CIDR blocks for the 3 AWS VPCs"
  type        = list(string)
  default     = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
}

variable "azure_locations" {
  description = "Azure regions to create resources in (3 entries)"
  type        = list(string)
  default     = ["westus2", "westus", "eastus2"]
}

variable "azure_vnet_cidrs" {
  description = "CIDR blocks for each Azure VNet"
  type        = list(string)
  default     = ["10.10.0.0/16", "10.11.0.0/16", "10.12.0.0/16"]
}

variable "admin_ssh_public_key" {
  description = "Optional SSH public key for VMs; if empty a key is generated locally and used"
  type        = string
  default     = ""
}

variable "gcp_project" {
  description = "GCP project ID"
  type        = string
  default     = "" # Set via terraform.tfvars or environment
}

variable "gcp_regions" {
  description = "List of GCP regions to create VPCs in"
  type        = list(string)
  default     = ["us-west1", "us-central1", "us-east1"]
}

variable "gcp_subnet_cidrs" {
  description = "CIDR blocks for GCP subnets"
  type        = list(string)
  default     = ["10.20.0.0/16", "10.21.0.0/16", "10.22.0.0/16"]
}

variable "oci_tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
  default     = "" # Set via terraform.tfvars or environment
}

variable "oci_regions" {
  description = "List of OCI regions to create VCNs in"
  type        = list(string)
  default     = ["us-phoenix-1", "us-ashburn-1", "ca-toronto-1"]
}

variable "oci_vcn_cidrs" {
  description = "CIDR blocks for OCI VCNs"
  type        = list(string)
  default     = ["10.30.0.0/16", "10.31.0.0/16", "10.32.0.0/16"]
}

variable "oci_compartment_id" {
  description = "OCI compartment ID"
  type        = string
  default     = "" # Set via terraform.tfvars or environment
}
