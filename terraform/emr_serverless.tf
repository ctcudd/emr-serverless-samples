resource "aws_emrserverless_application" "EmrServerlessSparkApp" {
  release_label = "emr-6.6.0"
  type          = "spark"
  name          = "spark-3.2"
  maximum_capacity {
    cpu = "200 vCPU"
    memory = "100 GB"
  }
  network_configuration {
    security_group_ids=[aws_security_group.EMRServerlessSG.id]
    subnet_ids=local.private_subnets
  }
  auto_start_configuration {
    enabled = true
  }
  auto_stop_configuration {
    enabled = true
  }
  initial_capacity {
    initial_capacity_type = "Driver"

    initial_capacity_config {
      worker_count = 3
      worker_configuration {
        cpu    = "2 vCPU"
        memory = "4 GB"
        disk   = "21 GB"
      }
    }
  }
  initial_capacity {
    initial_capacity_type = "Executor"

    initial_capacity_config {
      worker_count = 4
      worker_configuration {
        cpu    = "1 vCPU"
        memory = "4 GB"
        disk   = "20 GB"
      }
    }
  }

}
resource "aws_security_group" "EMRServerlessSG" {
  vpc_id = aws_vpc.Main.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


output "emr_serverless_application_id" {
  value = aws_emrserverless_application.EmrServerlessSparkApp.id
}
output "emr_serverless_job_role" {
  value = aws_iam_role.emr-serverless-job-role.arn
}
output "emr_serverless_log_bucket" {
  value = aws_s3_bucket.bucket.bucket
}
