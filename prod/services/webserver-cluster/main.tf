provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-masuda-state"
    key    = "prod/services/webserver-cluster/terraform.tfstate"
    region = "us-west-2"
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "terraform-up-and-running-masuda-state"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"
  instance_type          = "m4.large"
  min_size               = 2
  max_size               = 10
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capcity       = 10
  recurrence            = "0 9 * * *"

  #pegando informação do output.tf
  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
}

#This code uses one aws_autoscaling_schedule resource to increase the number of servers to 10 during the morninghours (the recurrence parameter uses cron syntax, so "0 9 * * *" means “9 a.m. every day”) and a secondaws_autoscaling_schedule resource to decrease the number of servers at night ("0 17 * * *" means “5 p.m. every day”)
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name  = "scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
}

# Sempre que alterar algum arquivo no diretório modules, é necessário executar o comando terraform get antes de executar o apply ou o plan.

