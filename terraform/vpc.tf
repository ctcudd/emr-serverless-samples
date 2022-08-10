# Declare the data source for az
data "aws_availability_zones" "available" {
  state = "available"
}
# Create the VPC
resource "aws_vpc" "Main" {                # Creating VPC here
  cidr_block       = var.main_vpc_cidr     # Defining the CIDR block use 10.0.0.0/24 for demo
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "emr-serverless-demo-vpc"
    for-use-with-amazon-emr-managed-policies = true
  }
}

resource "aws_vpc_dhcp_options_association" "vpc_dhcp_options_association" {
  vpc_id          = aws_vpc.Main.id
  dhcp_options_id = aws_vpc_dhcp_options.vpc_dhcp_options.id
}
locals {
  regional_domain_name = "${var.region}.compute.internal"
  dhcp_domain_name = var.region == "us-east-1" ? "ec2.internal" : local.regional_domain_name
}
resource "aws_vpc_dhcp_options" "vpc_dhcp_options" {
  domain_name_servers = ["AmazonProvidedDNS"]
  domain_name = local.dhcp_domain_name
}

# Create Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "IGW" {
  vpc_id =  aws_vpc.Main.id
}

# Create a Public Subnet.
resource "aws_subnet" "publicsubnet" {
  vpc_id =  aws_vpc.Main.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.public_subnet
  map_public_ip_on_launch = true
  tags = {
    Name = "emr-serverless-demo-PublicSubnet"
    for-use-with-amazon-emr-managed-policies = true
  }
}

# Create Private Subnets
resource "aws_subnet" "private_subnet_one" {
  vpc_id =  aws_vpc.Main.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.private_subnet_one
  tags = {
    Name = "emr-serverless-demo-PrivateSubnetOne"
    for-use-with-amazon-emr-managed-policies = true
  }
}
resource "aws_subnet" "private_subnet_two" {
  vpc_id =  aws_vpc.Main.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = var.private_subnet_two
  tags = {
    Name = "emr-serverless-demo-PrivateSubnetTwo"
    for-use-with-amazon-emr-managed-policies = true
  }
}
resource "aws_subnet" "private_subnet_three" {
  vpc_id =  aws_vpc.Main.id
  availability_zone = data.aws_availability_zones.available.names[2]
  cidr_block = var.private_subnet_three
  tags = {
    Name = "emr-serverless-demo-PrivateSubnetThree"
    for-use-with-amazon-emr-managed-policies = true
  }
}

#create NAT gateway eip
resource "aws_eip" "nateIP" {
  depends_on = [aws_internet_gateway.IGW]
  vpc   = true
}
# Creating the NAT Gateway using subnet_id and allocation_id
resource "aws_nat_gateway" "NATgw" {
  allocation_id = aws_eip.nateIP.id
  subnet_id = aws_subnet.publicsubnet.id
}

# Route table for Public Subnet's
resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
  vpc_id =  aws_vpc.Main.id
  route {
    cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
  }
}

# Route table for Private Subnet's
resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
  vpc_id = aws_vpc.Main.id
  route {
    cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
    nat_gateway_id = aws_nat_gateway.NATgw.id
  }
}
# Route table Association with Public Subnet's
resource "aws_route_table_association" "PublicRTassociation" {
  subnet_id = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.PublicRT.id
}
# Route table Association with Private Subnet's
resource "aws_route_table_association" "PrivateRTassociation1" {
  subnet_id = aws_subnet.private_subnet_one.id
  route_table_id = aws_route_table.PrivateRT.id
}
resource "aws_route_table_association" "PrivateRTassociation2" {
  subnet_id = aws_subnet.private_subnet_two.id
  route_table_id = aws_route_table.PrivateRT.id
}
resource "aws_route_table_association" "PrivateRTassociation3" {
  subnet_id = aws_subnet.private_subnet_three.id
  route_table_id = aws_route_table.PrivateRT.id
}
output "vpc_id" {
  value = aws_vpc.Main.id
}
output "public_subnets" {
  value = [aws_subnet.publicsubnet.id]
}

output "private_subnets" {
  value = [aws_subnet.private_subnet_one.id, aws_subnet.private_subnet_two.id, aws_subnet.private_subnet_three.id]
}

locals {
  private_subnets = [aws_subnet.private_subnet_one.id, aws_subnet.private_subnet_two.id, aws_subnet.private_subnet_three.id]
}
