variable "latest_ami_id" {
  default = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

variable "project_tag" {
  description = "Tag value applied to all resources"
  type = string
  default = "emr-serverless-demo"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "mwaa_environment_name" {
  type        = string
  default     = "emr-serverless-airflow"
}


variable "main_vpc_cidr" {}
variable "public_subnet" {}
variable "private_subnet_one" {}
variable "private_subnet_two" {}
variable "private_subnet_three" {}
