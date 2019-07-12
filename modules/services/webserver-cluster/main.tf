provider "aws" {
  region = "us-west-2"
}

# Nova configuração para o tfstate remote

#terraform {
#  backend "s3" {
#    bucket = "${var.remote_state_bucket}"
#    key    = "${var.remote_state_key}"
#    region = "us-west-2"
#  }
#}

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "${var.db_remote_state_bucket}"
    key    = "${var.db_remote_state_key}"
    region = "us-west-2"
  }
}

data "template_file" "initializing" {
  #Arquivo template
  #template = "${file("init.sh")}"
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    #Pegando variável do arquivo var.tf
    server_port = "${var.server_port}"

    #Pegando variáveis do output que estão armazenados no s3 terraform-up-and-running-masuda-state/stage/data-stores/mysql
    db_address = "${data.terraform_remote_state.db.address}"
    db_port    = "${data.terraform_remote_state.db.port}"
  }
}

resource "aws_launch_configuration" "masuda" {
  image_id        = "ami-07b4f3c02c7f83d59"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data       = "${data.template_file.initializing.rendered}"

  #user_data = <<-EOF
  #!/bin/bash
  #            echo "Hello World" >> index.html
  #            echo "${data.terraform_remote_state.db.address}" >> index.html
  #            echo "${data.terraform_remote_state.db.port}" >> index.html
  #            nohup busybox httpd -f -p "${var.server_port}" &
  #            EOF

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
  load_balancers       = ["${aws_elb.masuda-elb.name}"]
  health_check_type    = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key                 = "Masuda"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }
}

#resource "aws_security_group" "instance" {
#  name = "${var.cluster_name}-instance"

#  ingress {
#    from_port   = "${var.server_port}"
#    to_port     = "${var.server_port}"
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  ingress {
#    from_port   = "${var.ssh_port}"
#    to_port     = "${var.ssh_port}"
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  lifecycle {
#    create_before_destroy = true
#  }
#}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_instance_http_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.instance.id}"

  from_port   = "${var.server_port}"
  to_port     = "${var.server_port}"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "allow_ssh" {
  name              = "${aws_security_group.instance.id}"
  type              = "ingress"
  security_group_id = "${aws_security_group.instance.id}"

  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

#resource "aws_security_group" "elb" {
#  name = "${var.cluster_name}-elb-security_group"
#
#  ingress {
#    from_port   = 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}

resource "aws_security_group" "elb" {
  name = "${var.cluster_name}-elb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port  = 80
  to_port    = 80
  protocol   = "tcp"
  cidr_block = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_elb" "masuda-elb" {
  name               = "${var.cluster_name}-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
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
