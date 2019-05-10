provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "masuda" {
  ami           = "ami-005bdb005fb00e791"
  instance_type = "t2.micro"

  tags {
    Name = "terraform-masuda-exemplo"
  }
}
