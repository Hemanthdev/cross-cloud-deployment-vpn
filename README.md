# Multi-Cloud Infrastructure as Code

This repository contains Terraform configuration for deploying infrastructure across AWS, Azure, Google Cloud, and Oracle Cloud. 

## Architecture

- **3 Regions per Cloud Provider**: Deployed across geographically diverse regions
- **VPC/VNet setup**: 1 VPC/VNet per region with 1 public and 2 private subnets each
- **Compute Instances**: EC2/VM instances deployed in private subnets for security
- **Cross-Region Peering**: VPC/VNet peering configured between all regions for inter-region communication
- **Route Tables**: Configured for both public internet access and private peering traffic
- **Security Groups/NSGs**: Restricted SSH access to within VPC/VNet CIDR ranges

## Provider Configuration

### AWS
- **Regions**: us-west-2, us-west-1, us-east-1
- **VPC CIDR Blocks**: 10.0.0.0/16, 10.1.0.0/16, 10.2.0.0/16
- **Instance Type**: t3.micro

### Azure
- **Locations**: westus2, westus, eastus2
- **VNet CIDR Blocks**: 10.10.0.0/16, 10.11.0.0/16, 10.12.0.0/16
- **VM Size**: Standard_B1s

### Google Cloud Platform (GCP)
- **Regions**: us-west1, us-central1, us-east1
- **Subnet CIDR Blocks**: 10.20.0.0/16, 10.21.0.0/16, 10.22.0.0/16
- **Machine Type**: e2-micro

### Oracle Cloud Infrastructure (OCI)
- **Regions**: us-phoenix-1, us-ashburn-1, ca-toronto-1
- **VCN CIDR Blocks**: 10.30.0.0/16, 10.31.0.0/16, 10.32.0.0/16
- **Instance Shape**: VM.Standard.E3.Flex (1 OCPU, 1 GB memory)

## Files

- `providers.tf` - Provider configuration for all cloud platforms
- `variables.tf` - All variables with defaults for regions, CIDR blocks, and cloud credentials
- `aws.tf` - AWS resources (VPCs, subnets, instances, peering, route tables)
- `azure.tf` - Azure resources (Resource Groups, VNets, VMs, peering)
- `gcp.tf` - GCP resources (VPCs, subnets, instances, peering)
- `oci.tf` - OCI resources (VCNs, subnets, instances, peering)

## Prerequisites

1. **Terraform** >= 1.7.0
2. **Cloud Provider Credentials**:
   - AWS: `~/.aws/credentials` or environment variables
   - Azure: `az login` or environment variables
   - GCP: `GOOGLE_APPLICATION_CREDENTIALS` environment variable pointing to service account JSON
   - OCI: `~/.oci/config` file with appropriate credentials

## Usage

### Initialize Terraform
```bash
terraform init
```

### Format Code
```bash
terraform fmt -recursive .
```

### Plan Deployment
```bash
terraform plan -out=tfplan
```

### Apply Configuration
```bash
terraform apply tfplan
```

### Destroy Resources
```bash
terraform destroy
```

## Variables

To override default variables, create a `terraform.tfvars` file:

```hcl
gcp_project       = "your-gcp-project-id"
oci_tenancy_ocid  = "ocid1.tenancy.oc1..."
oci_compartment_id = "ocid1.compartment.oc1..."
admin_ssh_public_key = "ssh-rsa AAAA..."
```

## Outputs

After applying, Terraform will output:
- AWS VPC IDs and instance details
- Azure VNet IDs and VM private IPs
- GCP VPC IDs and VM internal IPs
- OCI VCN IDs and instance private IPs

## Notes

- SSH keys are auto-generated if not provided
- All instances are deployed in private subnets for security
- Cross-region peering enables communication between regions
- Route tables are configured with appropriate peering routes
