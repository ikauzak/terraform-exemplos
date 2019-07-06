provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3"{
    bucket = "terraform-up-and-running-masuda-state"
    key    = "global/s3/terraform.tfstate"
    region = "us-west-2"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-masuda-state"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
