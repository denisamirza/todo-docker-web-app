provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch=true
  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "Private-Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "route_table"
  }
}

resource "aws_route_table" "rt-local" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat.id
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.rt-local.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt-public.id
}

resource "aws_security_group" "web-sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database-sg" {
  name   = "SSH"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "key" {
    key_name = "my-key"
    public_key = file("/home/deni/.ssh/id_rsa.pub")
}

resource "aws_instance" "frontend" {
  ami           = "ami-0533f2ba8a1995cf9"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]

  user_data = <<-EOF
              #!/bin/bash -ex
              sudo yum update -y
              sudo yum install git -y
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              git clone https://github.com/denisamirza/todo-docker-web-app.git
              EOF

  tags = {
    "Name" : "frontend"
  }
}

resource "aws_instance" "backend" {
  ami           = "ami-0533f2ba8a1995cf9"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]


  user_data = <<-EOF
              #!/bin/bash -ex
              sudo yum update -y
              sudo yum install git -y
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              git clone https://github.com/denisamirza/todo-docker-web-app.git
              EOF

  tags = {
    "Name" : "backend"
  }
}

resource "aws_instance" "database" {
  ami           = "ami-0533f2ba8a1995cf9"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name

  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.database-sg.id]


  user_data = <<-EOF
              #!/bin/bash -ex
              sudo yum update -y
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              EOF

  tags = {
    "Name" : "database"
  }
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "nat-gateway"
  }
}

resource "null_resource" "copy_file" {
  provisioner "local-exec" {
    command = "scp -i /home/deni/.ssh/id_rsa -r /home/deni/.ssh ec2-user@${aws_instance.backend.public_ip}:/home/ec2-user"
  }
  
  depends_on = [aws_instance.backend]
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}

