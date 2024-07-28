// after creating provider file we need to crerate vpc , here we are using modules

// below code for no.of availabity zones
data "aws_availability_zones" "available" {}

//creating vpc
resource "aws_vpc" "eksvpc" {
    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true

  tags = {
    Name = "main_vpcfor_eksCLuster"
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 

// creating internetGateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eksvpc.id

  tags = {
    "Name" = "igw"
  } 
}

//creating 2 public subnets
resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.eksvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = var.availability_zone[0]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "publicsubnet-useast-1a"
  }
}

resource "aws_subnet" "public_subnet2" {
    vpc_id = aws_vpc.eksvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone[1]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "publicsubnet-useast-1b"
  }
  
}
//creating private subnets
resource "aws_subnet" "private_subnet1" {
  vpc_id = aws_vpc.eksvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zone[2]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "privatesubnet-useast-1c"
  }
  
}


resource "aws_subnet" "private_subnet2" {
  vpc_id = aws_vpc.eksvpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = var.availability_zone[3]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "privatesubnet-useast-1d"
  }

}

resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "nat"
  }
}

//creating natGateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

//now we have to create route table and route table association

resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.eksvpc.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "publicroutetable"
  }

}
  
resource "aws_route_table_association" "publicRouteTable1Association" {
  subnet_id = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.publicRouteTable.id

}

resource "aws_route_table_association" "publicRouteTable2Association" {
  subnet_id = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.publicRouteTable.id

}

resource "aws_route_table" "privateRouteTable" {
  vpc_id = aws_vpc.eksvpc.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "privateroutetable"
  }


}
  
resource "aws_route_table_association" "privateRouteTable1Association" {
  subnet_id = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.publicRouteTable.id

}

resource "aws_route_table_association" "privateRouteTable2Association" {
  subnet_id = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.publicRouteTable.id

}

//*********************************************************************************//

//Nat gateways:

# Configure Elastic IP as static IP for your NAT gateway
resource "aws_eip" "nat" {
  # EIP may require IGW to exist prior to association. 
  # Use depends_on to set an explicit dependency on the IGW.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "natGateway" {
  allocation_id = aws_eip.nat.id

  # The Subnet ID of the subnet in which to place the gateway.
  subnet_id = aws_subnet.public_subnet1.id
  
  tags = {
    Name = "ngw"
  }
}
