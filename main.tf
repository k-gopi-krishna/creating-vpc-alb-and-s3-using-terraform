provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "proj2" { #creating a vpc 
  cidr_block = "12.0.0.0/16"
  tags = {
    Name = "proj2"
  }
}

resource "aws_subnet" "pubsn1" { #creating a public subnet in 1a az
  vpc_id                  = aws_vpc.proj2.id
  cidr_block              = "12.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true  #enabling public ip on launch
}
resource "aws_subnet" "pubsn2" { #creating a public subnet in 1b az
  vpc_id                  = aws_vpc.proj2.id
  cidr_block              = "12.0.1.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true #enabling public ip on launch



}
resource "aws_internet_gateway" "igw2" { #creating an internet gateway in our vpc
  vpc_id = aws_vpc.proj2.id
}
resource "aws_route_table" "rt1" { #creating a route table which routes from igw into the vpc
  vpc_id = aws_vpc.proj2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw2.id
  }
}
resource "aws_route_table_association" "rt1a" { #associating the route table with the public subnet
  subnet_id      = aws_subnet.pubsn1.id
  route_table_id = aws_route_table.rt1.id

}

resource "aws_route_table_association" "rt1b" { #associating the route table with the public subnet
  subnet_id      = aws_subnet.pubsn2.id
  route_table_id = aws_route_table.rt1.id

}

resource "aws_security_group" "sgp2" { #creating a security group which allows traffic on port 80 and 22
  vpc_id = aws_vpc.proj2.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_s3_bucket" "myp2" { #creating an s3 bucket
  bucket = "kondajip2"

}
resource "aws_s3_bucket_public_access_block" "pubacc" { #giving public access to the s3 bucket
  bucket                  = aws_s3_bucket.myp2.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_ownership_controls" "sowm" { #giving ownership to the bucket owner
  bucket = aws_s3_bucket.myp2.id
  rule {
    object_ownership = "BucketOwnerPreferred"

  }

}
resource "aws_s3_bucket_acl" "bacl" { #making the s3 bucket public
  depends_on = [aws_s3_bucket_public_access_block.pubacc, aws_s3_bucket_ownership_controls.sowm]
  bucket     = aws_s3_bucket.myp2.id
  acl        = "public-read"
}

resource "aws_instance" "inst1" { #creating an ec2 instance in the public subnet 1
  ami                    = "ami-03bb6d83c60fc5f7c"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sgp2.id]
  subnet_id              = aws_subnet.pubsn1.id
  user_data              = base64encode(file("userdata.sh")) #uploading and running userdata script

}
resource "aws_instance" "inst2" {#creating an ec2 instance in the public subnet 1
  ami                    = "ami-03bb6d83c60fc5f7c"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sgp2.id]
  subnet_id              = aws_subnet.pubsn2.id
  user_data              = base64encode(file("userdata1.sh"))
}
resource "aws_lb" "myalbp2" { #creating an application load balancer
  name               = "myalbp2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sgp2.id]
  subnets            = [aws_subnet.pubsn1.id, aws_subnet.pubsn2.id]
  tags = {
    Name = "myalbp2"
  }
}

resource "aws_lb_target_group" "lbtg" { #creating a target group
  name     = "mytg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.proj2.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "tgatt1" { #attaching the target group to the ec2 instances
  target_group_arn = aws_lb_target_group.lbtg.arn
  target_id        = aws_instance.inst1.id
  port             = 80

}
resource "aws_lb_target_group_attachment" "tgatt2" {    #attaching the target group to the ec2 instances
  target_group_arn = aws_lb_target_group.lbtg.arn
  target_id        = aws_instance.inst2.id
  port             = 80
}

resource "aws_lb_listener" "tgl" { #creating a listener for the load balancer
  load_balancer_arn = aws_lb.myalbp2.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg.arn
  }

}
