# Multi-Cloud VPN Configuration Guide

## Overview

This Terraform configuration establishes secure VPN connections between AWS, Azure, Google Cloud Platform (GCP), and Oracle Cloud Infrastructure (OCI). The VPN setup creates a hub-and-spoke topology with cross-cloud IPSec tunnels.

## Architecture

```
    ┌─────────────┐
    │     AWS     │
    │  VPN GW     │
    └──────┬──────┘
           │
           │ IPSec Tunnel
           │
    ┌──────┴──────┐
    │    Azure    │
    │  VPN GW     │
    └──────┬──────┘
           │
           │ IPSec Tunnel
           │
    ┌──────┴──────┐
    │     GCP     │
    │  VPN GW     │
    └──────┬──────┘
           │
           │ IPSec Tunnel
           │
    ┌──────┴──────┐
    │     OCI     │
    │    DRG      │
    └─────────────┘
```

## VPN Components by Cloud Provider

### AWS
- **Virtual Private Gateway (VGW)**: Located in us-west-2 region
- **Customer Gateway**: Points to Azure VPN Gateway public IP
- **VPN Connection**: IPSec tunnel to Azure
- **Route Propagation**: Routes to peered VPCs

### Azure
- **VPN Gateway**: Standard SKU in westus2 region
- **Public IP**: Static IP for VPN endpoint
- **Local Network Gateway**: Represents AWS VPN endpoint
- **VPN Connection**: IPSec connection to AWS

### GCP
- **Cloud VPN Gateway**: In us-west1 region
- **Forwarding Rules**: ESP, UDP 500, UDP 4500 for IPSec
- **VPN Tunnel**: IPSec tunnel to AWS
- **Routes**: Routes to AWS CIDR blocks

### OCI
- **Dynamic Routing Gateway (DRG)**: Hub for all VCN attachments
- **DRG Attachments**: Connects all 3 VCNs to DRG
- **IPSec Connection**: Site-to-Site VPN to AWS
- **Customer Premises Equipment (CPE)**: Represents AWS endpoint

## Enabling/Disabling VPN

The VPN configuration is controlled by the `vpn_enabled` variable:

```hcl
vpn_enabled = true  # Enable VPN
vpn_enabled = false # Disable VPN (default: true)
```

## VPN Pre-Shared Key

A pre-shared key (PSK) is required for IPSec authentication. Set it in `terraform.tfvars`:

```hcl
vpn_preshared_key = "YourSecurePreSharedKey123456"
```

**Important**: Change the default PSK in production. Use a strong, random key with:
- Minimum 20 characters
- Mix of uppercase, lowercase, numbers, and special characters
- Example: `Secure@VPN#Key$2024!MultiCloud`

## Deployment Steps

### 1. Prepare Configuration

Create `terraform.tfvars`:
```hcl
gcp_project         = "your-gcp-project-id"
oci_tenancy_ocid    = "ocid1.tenancy.oc1..."
oci_compartment_id  = "ocid1.compartment.oc1..."
vpn_enabled         = true
vpn_preshared_key   = "YourSecurePreSharedKeyHere"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Plan

```bash
terraform plan -out=tfplan
```

### 4. Apply Configuration

```bash
terraform apply tfplan
```

### 5. Verify VPN Status

Check outputs:
```bash
terraform output aws_vpn_gateway_id
terraform output azure_vpn_gateway_id
terraform output gcp_vpn_gateway_id
terraform output oci_drg_id
```

## Connectivity Testing

### From AWS Instance
```bash
# SSH into AWS instance
ssh -i key.pem ec2-user@instance-ip

# Ping Azure subnet
ping 10.10.1.0

# Ping GCP subnet
ping 10.20.1.0

# Ping OCI VCN
ping 10.30.1.0
```

### From Azure VM
```bash
# SSH into Azure VM
ssh azureuser@vm-ip

# Ping AWS subnet
ping 10.0.1.0

# Ping GCP subnet
ping 10.20.1.0

# Ping OCI VCN
ping 10.30.1.0
```

## Files

- `vpn.tf` - VPN gateway configurations for all cloud providers
- `variables.tf` - VPN-related variables (vpn_enabled, vpn_preshared_key)
- `aws.tf`, `azure.tf`, `gcp.tf`, `oci.tf` - Base infrastructure (VPCs, subnets, instances)

## Limitations & Considerations

1. **Single VPN Connection**: Current setup creates IPSec tunnels between primary region gateways
2. **Regional Scope**: VPN gateways are region-specific; peering handles multi-region connectivity
3. **Bandwidth**: VPN throughput depends on cloud provider allocations (typically 1-10 Gbps)
4. **Latency**: Cross-cloud communication adds latency vs. single-cloud
5. **Cost**: VPN gateway charges apply per provider; data egress charges incur for cross-cloud traffic

## Troubleshooting

### VPN Connection Down
- Verify pre-shared keys match on both sides
- Check security groups/network ACLs allow UDP 500, UDP 4500, ESP
- Confirm public IPs are reachable from both endpoints

### Routing Issues
- Verify route tables include remote CIDR blocks
- Check firewall rules allow traffic between subnets
- Confirm BGP is disabled (static routes enabled)

### Tunnel Negotiation Failed
- Increase IKE/ESP lifetime parameters
- Verify IPSec policy compatibility (AES-128/256, SHA-1/256)
- Check firewall logging for dropped packets

## Scaling to More Regions

To add additional VPN connections:

1. Add region-specific variables
2. Create additional VPN gateway instances per region
3. Configure mesh topology (all gateways connect to all others)
4. Update route tables with new remote CIDRs

## Security Best Practices

1. **Change Default PSK**: Never use default pre-shared key
2. **Rotate Keys**: Rotate VPN keys quarterly
3. **Monitor Traffic**: Enable VPN logging on all providers
4. **Access Control**: Restrict VPN to specific security groups/NSGs
5. **Encryption**: Use AES-256 for phase 1 & 2 encryption
6. **DPD (Dead Peer Detection)**: Enable to detect tunnel failures

## Next Steps

After deployment:
1. Test connectivity between all cloud instances
2. Monitor VPN tunnel status in cloud consoles
3. Configure monitoring/alerting for tunnel health
4. Run failover tests
5. Document network topology and access procedures
