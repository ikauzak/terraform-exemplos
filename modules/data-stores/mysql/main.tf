provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3"{
    bucket = "terraform-up-and-running-masuda-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-west-2"
  }
}

resource "aws_db_instance" "masuda" {
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "masuda_database"
  username          = "admin"
  password          = "${var.db_password}"
  skip_final_snapshot = true
}
