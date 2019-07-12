output "elb_dns_name" {
  value = "${aws_elb.masuda-elb.dns_name}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.example.name}"
}
