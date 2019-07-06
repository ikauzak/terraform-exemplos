provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3"{
    bucket = "terraform-up-and-running-masuda-state"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-west-2"
  }
}


resource "aws_launch_configuration" "masuda" {
  image_id                    = "ami-07b4f3c02c7f83d59"
  instance_type          = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  key_name = "acesso-masuda"

  lifecycle {
    create_before_destroy = true
  }

#  tags {
#    Name = "terraform-exemplo"
#  }
}

resource "aws_autoscaling_group" "masuda" {
  launch_configuration = "${aws_launch_configuration.masuda.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.masuda-elb.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Masuda"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_elb" "masuda-elb" {
  name = "terraform-asg-example"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  security_groups      = ["${aws_security_group.elb.id}"]

  listener {
    lb_port     = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}



data "aws_availability_zones" "all" {}
