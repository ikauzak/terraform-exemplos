provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-masuda-state"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-west-2"
  }
}

# Referencia do módulo
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "terraform-up-and-running-masuda-state"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}

# Sempre que alterar algum arquivo no diretório modules, é necessário executar o comando terraform get antes de executar o apply ou o plan.

