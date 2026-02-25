# ===== AWS VPCs and Subnets =====
data "aws_availability_zones" "r1" {
}

data "aws_availability_zones" "r2" {
  provider = aws.r2
}

data "aws_availability_zones" "r3" {
  provider = aws.r3
}

resource "aws_vpc" "r1" {
  cidr_block = var.aws_vpc_cidrs[0]
  tags = {
    Name = "vpc-r1"
  }
}

resource "aws_vpc" "r2" {
  provider   = aws.r2
  cidr_block = var.aws_vpc_cidrs[1]
  tags = {
    Name = "vpc-r2"
  }
}

resource "aws_vpc" "r3" {
  provider   = aws.r3
  cidr_block = var.aws_vpc_cidrs[2]
  tags = {
    Name = "vpc-r3"
  }
}

# Public subnet (one) and two private subnets per VPC
resource "aws_subnet" "r1_public" {
  vpc_id            = aws_vpc.r1.id
  cidr_block        = cidrsubnet(aws_vpc.r1.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.r1.names[0]
  tags = {
    Name = "r1-public"
  }
}

resource "aws_subnet" "r1_private" {
  count             = 2
  vpc_id            = aws_vpc.r1.id
  cidr_block        = cidrsubnet(aws_vpc.r1.cidr_block, 8, 2 + count.index)
  availability_zone = data.aws_availability_zones.r1.names[count.index]
  tags = {
    Name = "r1-private-${count.index}"
  }
}

resource "aws_subnet" "r2_public" {
  provider          = aws.r2
  vpc_id            = aws_vpc.r2.id
  cidr_block        = cidrsubnet(aws_vpc.r2.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.r2.names[0]
  tags = {
    Name = "r2-public"
  }
}

resource "aws_subnet" "r2_private" {
  provider          = aws.r2
  count             = 2
  vpc_id            = aws_vpc.r2.id
  cidr_block        = cidrsubnet(aws_vpc.r2.cidr_block, 8, 2 + count.index)
  availability_zone = data.aws_availability_zones.r2.names[count.index]
  tags = {
    Name = "r2-private-${count.index}"
  }
}

resource "aws_subnet" "r3_public" {
  provider          = aws.r3
  vpc_id            = aws_vpc.r3.id
  cidr_block        = cidrsubnet(aws_vpc.r3.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.r3.names[0]
  tags = {
    Name = "r3-public"
  }
}

resource "aws_subnet" "r3_private" {
  provider          = aws.r3
  count             = 2
  vpc_id            = aws_vpc.r3.id
  cidr_block        = cidrsubnet(aws_vpc.r3.cidr_block, 8, 2 + count.index)
  availability_zone = data.aws_availability_zones.r3.names[count.index]
  tags = {
    Name = "r3-private-${count.index}"
  }
}

# ===== AWS Internet Gateways =====
resource "aws_internet_gateway" "r1_igw" {
  vpc_id = aws_vpc.r1.id
}

resource "aws_internet_gateway" "r2_igw" {
  provider = aws.r2
  vpc_id   = aws_vpc.r2.id
}

resource "aws_internet_gateway" "r3_igw" {
  provider = aws.r3
  vpc_id   = aws_vpc.r3.id
}

# ===== AWS Route Tables =====
resource "aws_route_table" "r1_public_rt" {
  vpc_id = aws_vpc.r1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.r1_igw.id
  }
}

resource "aws_route_table" "r1_private_rt" {
  vpc_id = aws_vpc.r1.id
}

resource "aws_route_table" "r2_public_rt" {
  provider = aws.r2
  vpc_id   = aws_vpc.r2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.r2_igw.id
  }
}

resource "aws_route_table" "r2_private_rt" {
  provider = aws.r2
  vpc_id   = aws_vpc.r2.id
}

resource "aws_route_table" "r3_public_rt" {
  provider = aws.r3
  vpc_id   = aws_vpc.r3.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.r3_igw.id
  }
}

resource "aws_route_table" "r3_private_rt" {
  provider = aws.r3
  vpc_id   = aws_vpc.r3.id
}

# ===== AWS Route Table Associations =====
resource "aws_route_table_association" "r1_pub_assoc" {
  subnet_id      = aws_subnet.r1_public.id
  route_table_id = aws_route_table.r1_public_rt.id
}

resource "aws_route_table_association" "r1_priv_assoc" {
  count          = 2
  subnet_id      = aws_subnet.r1_private[count.index].id
  route_table_id = aws_route_table.r1_private_rt.id
}

resource "aws_route_table_association" "r2_pub_assoc" {
  provider       = aws.r2
  subnet_id      = aws_subnet.r2_public.id
  route_table_id = aws_route_table.r2_public_rt.id
}

resource "aws_route_table_association" "r2_priv_assoc" {
  provider       = aws.r2
  count          = 2
  subnet_id      = aws_subnet.r2_private[count.index].id
  route_table_id = aws_route_table.r2_private_rt.id
}

resource "aws_route_table_association" "r3_pub_assoc" {
  provider       = aws.r3
  subnet_id      = aws_subnet.r3_public.id
  route_table_id = aws_route_table.r3_public_rt.id
}

resource "aws_route_table_association" "r3_priv_assoc" {
  provider       = aws.r3
  count          = 2
  subnet_id      = aws_subnet.r3_private[count.index].id
  route_table_id = aws_route_table.r3_private_rt.id
}

# ===== AWS Security Groups =====
resource "aws_security_group" "r1_sg" {
  name   = "r1-sg"
  vpc_id = aws_vpc.r1.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.r1.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "r2_sg" {
  provider = aws.r2
  name     = "r2-sg"
  vpc_id   = aws_vpc.r2.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.r2.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "r3_sg" {
  provider = aws.r3
  name     = "r3-sg"
  vpc_id   = aws_vpc.r3.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.r3.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ===== AWS AMI Data =====
data "aws_ami" "r1_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "r2_ami" {
  provider    = aws.r2
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "r3_ami" {
  provider    = aws.r3
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ===== AWS EC2 Instances =====
resource "aws_instance" "r1_instance" {
  ami                    = data.aws_ami.r1_ami.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.r1_private[0].id
  vpc_security_group_ids = [aws_security_group.r1_sg.id]
}

resource "aws_instance" "r2_instance" {
  provider               = aws.r2
  ami                    = data.aws_ami.r2_ami.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.r2_private[0].id
  vpc_security_group_ids = [aws_security_group.r2_sg.id]
}

resource "aws_instance" "r3_instance" {
  provider               = aws.r3
  ami                    = data.aws_ami.r3_ami.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.r3_private[0].id
  vpc_security_group_ids = [aws_security_group.r3_sg.id]
}

# ===== AWS VPC Peering =====
resource "aws_vpc_peering_connection" "r1_r2" {
  vpc_id      = aws_vpc.r1.id
  peer_vpc_id = aws_vpc.r2.id
  peer_region = var.aws_regions[1]
  auto_accept = true
}

resource "aws_vpc_peering_connection" "r1_r3" {
  vpc_id      = aws_vpc.r1.id
  peer_vpc_id = aws_vpc.r3.id
  peer_region = var.aws_regions[2]
  auto_accept = true
}

resource "aws_vpc_peering_connection" "r2_r3" {
  provider    = aws.r2
  vpc_id      = aws_vpc.r2.id
  peer_vpc_id = aws_vpc.r3.id
  peer_region = var.aws_regions[2]
  auto_accept = true
}

# ===== AWS Peering Routes =====
resource "aws_route" "r1_to_r2" {
  route_table_id            = aws_route_table.r1_private_rt.id
  destination_cidr_block    = aws_vpc.r2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.r1_r2.id
}

resource "aws_route" "r2_to_r1" {
  provider                  = aws.r2
  route_table_id            = aws_route_table.r2_private_rt.id
  destination_cidr_block    = aws_vpc.r1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.r1_r2.id
}

resource "aws_route" "r1_to_r3" {
  route_table_id            = aws_route_table.r1_private_rt.id
  destination_cidr_block    = aws_vpc.r3.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.r1_r3.id
}

resource "aws_route" "r3_to_r1" {
  provider                  = aws.r3
  route_table_id            = aws_route_table.r3_private_rt.id
  destination_cidr_block    = aws_vpc.r1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.r1_r3.id
}

resource "aws_route" "r2_to_r3" {
  provider                  = aws.r2
  route_table_id            = aws_route_table.r2_private_rt.id
  destination_cidr_block    = aws_vpc.r3.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.r2_r3.id
}

resource "aws_route" "r3_to_r2" {
  provider                  = aws.r3
  route_table_id            = aws_route_table.r3_private_rt.id
  destination_cidr_block    = aws_vpc.r2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.r2_r3.id
}

output "aws_vpc_ids" {
  value = {
    r1 = aws_vpc.r1.id
    r2 = aws_vpc.r2.id
    r3 = aws_vpc.r3.id
  }
}
