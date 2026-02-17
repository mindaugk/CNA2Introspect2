# Reference the VPC (assuming vpc.tf is in the same directory)
# If vpc.tf is applied separately, use data source instead
# data "aws_vpc" "main" {
#   id = "vpc-0106a409337544694"
# }

# us-east-1a - Private subnet (first half of /22)
resource "aws_subnet" "private_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/23"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name                                      = "private-subnet-us-east-1a"
    Type                                      = "private"
    Environment                               = "dev"
    ManagedBy                                 = "terraform"
    "kubernetes.io/cluster/mk-cluster"       = "shared"
    "kubernetes.io/role/internal-elb"        = "1"
  }
}

# us-east-1a - Public subnet (second half of /22)
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/23"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "public-subnet-us-east-1a"
    Type                                      = "public"
    Environment                               = "dev"
    ManagedBy                                 = "terraform"
    "kubernetes.io/cluster/mk-cluster"       = "shared"
    "kubernetes.io/role/elb"                 = "1"
  }
}

# us-east-1b - Private subnet (first half of /22)
resource "aws_subnet" "private_subnet_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/23"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name                                      = "private-subnet-us-east-1b"
    Type                                      = "private"
    Environment                               = "dev"
    ManagedBy                                 = "terraform"
    "kubernetes.io/cluster/mk-cluster"       = "shared"
    "kubernetes.io/role/internal-elb"        = "1"
  }
}

# us-east-1b - Public subnet (second half of /22)
resource "aws_subnet" "public_subnet_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/23"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "public-subnet-us-east-1b"
    Type                                      = "public"
    Environment                               = "dev"
    ManagedBy                                 = "terraform"
    "kubernetes.io/cluster/mk-cluster"       = "shared"
    "kubernetes.io/role/elb"                 = "1"
  }
}

# us-east-1c - Private subnet (first half of /22)
resource "aws_subnet" "private_subnet_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.8.0/23"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name                                      = "private-subnet-us-east-1c"
    Type                                      = "private"
    Environment                               = "dev"
    ManagedBy                                 = "terraform"
    "kubernetes.io/cluster/mk-cluster"       = "shared"
    "kubernetes.io/role/internal-elb"        = "1"
  }
}

# us-east-1c - Public subnet (second half of /22)
resource "aws_subnet" "public_subnet_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/23"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "public-subnet-us-east-1c"
    Type                                      = "public"
    Environment                               = "dev"
    ManagedBy                                 = "terraform"
    "kubernetes.io/cluster/mk-cluster"       = "shared"
    "kubernetes.io/role/elb"                 = "1"
  }
}

# us-east-1d - Public subnet (keeping existing)
resource "aws_subnet" "public_subnet_1d" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.12.0/22"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "public-subnet-us-east-1d"
    Type                                      = "public"
    Environment                               = "dev"
    ManagedBy                                 = "terraform"
    "kubernetes.io/cluster/mk-cluster"       = "shared"
    "kubernetes.io/role/elb"                 = "1"
  }
}

# Outputs
output "private_subnet_1a_id" {
  description = "ID of private subnet in us-east-1a"
  value       = aws_subnet.private_subnet_1a.id
}

output "public_subnet_1a_id" {
  description = "ID of public subnet in us-east-1a"
  value       = aws_subnet.public_subnet_1a.id
}

output "private_subnet_1b_id" {
  description = "ID of private subnet in us-east-1b"
  value       = aws_subnet.private_subnet_1b.id
}

output "public_subnet_1b_id" {
  description = "ID of public subnet in us-east-1b"
  value       = aws_subnet.public_subnet_1b.id
}

output "private_subnet_1c_id" {
  description = "ID of private subnet in us-east-1c"
  value       = aws_subnet.private_subnet_1c.id
}

output "public_subnet_1c_id" {
  description = "ID of public subnet in us-east-1c"
  value       = aws_subnet.public_subnet_1c.id
}

output "public_subnet_1d_id" {
  description = "ID of public subnet in us-east-1d"
  value       = aws_subnet.public_subnet_1d.id
}

output "private_subnet_ids" {
  description = "List of all private subnet IDs"
  value       = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1b.id,
    aws_subnet.private_subnet_1c.id
  ]
}

output "public_subnet_ids" {
  description = "List of all public subnet IDs"
  value       = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1b.id,
    aws_subnet.public_subnet_1c.id,
    aws_subnet.public_subnet_1d.id
  ]
}
