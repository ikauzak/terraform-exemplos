provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "masuda" {
  ami                    = "ami-005bdb005fb00e791"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  key_name = "acesso-masuda"

  tags {
    Name = "terraform-exemplo"
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
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

variable "ssh_port" {
  description = "The port the server will open for SSH access"
  default = 22
}

output "public_ip" {
  value = "${aws_instance.masuda.public_ip}"
}
