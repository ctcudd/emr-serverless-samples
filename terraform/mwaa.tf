resource "aws_mwaa_environment" "EMRServerlessAirflow" {
  dag_s3_path        = "dags/"
  execution_role_arn = aws_iam_role.MWAAServiceRole.arn
  name               = var.mwaa_environment_name
  airflow_version = "2.2.2"
  requirements_s3_path = "requirements.txt"
  webserver_access_mode = "PUBLIC_ONLY"
  environment_class = "mw1.small"
  depends_on = [aws_s3_object.airflow_objects, aws_iam_role_policy_attachment.MWAAServiceRoleAttach]
  network_configuration {
    security_group_ids = [aws_security_group.MWAASG.id]
    subnet_ids         = [aws_subnet.private_subnet_one.id, aws_subnet.private_subnet_two.id]
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }


  source_bucket_arn = aws_s3_bucket.bucket.arn
}
resource "aws_security_group" "MWAASG" {
  vpc_id = aws_vpc.Main.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self = true
  }
}

resource "aws_iam_role_policy_attachment" "MWAAServiceRoleAttach" {
  role       = aws_iam_role.MWAAServiceRole.name
  policy_arn = aws_iam_policy.MWAAServiceRolePolicy.arn
}


resource "aws_iam_role" "MWAAServiceRole" {
  name = "MWAAServiceRole"
  path = "/service-role/"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": ["airflow-env.amazonaws.com", "airflow.amazonaws.com"]
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_policy" "MWAAServiceRolePolicy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAirflowPublishMetrics"
        Action = [
          "airflow:PublishMetrics"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:airflow:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:environment/${var.mwaa_environment_name}"
      },
      {
        Sid = "AllowBucketAccess"
        Action = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.bucket.arn}/*", aws_s3_bucket.bucket.arn]
      },
      {
        Sid = "AllowLogsAccess"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Sid = "AllowDescribeLogsAccess"
        Action = [
          "logs:DescribeLogGroups",
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Sid = "AllowSqsAccess"
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:sqs:${data.aws_region.current.name}:*:airflow-celery-*"]
      },
      {
        Sid = "KMSAccess"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ]
        Effect   = "Allow"
        NotResource = "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "sqs.${data.aws_region.current.name}.amazonaws.com",
              "s3.${data.aws_region.current.name}.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid = "AllowEMRServerlessMgmt"
        Action = [
          "emr-serverless:CreateApplication",
          "emr-serverless:GetApplication",
          "emr-serverless:StartApplication",
          "emr-serverless:StopApplication",
          "emr-serverless:DeleteApplication",
          "emr-serverless:StartJobRun",
          "emr-serverless:GetJobRun"
        ]
        Effect   = "Allow"
        Resource = [
          "*",
        ]
      },
      {
        Sid = "AllowPassEMRServerlessJobRole"
        Action = [
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = [
          aws_iam_role.emr-serverless-job-role.arn,
        ]
        Condition = {
          StringLike = {
            "iam:PassedToService" = "emr-serverless.amazonaws.com"
          }
        }
      }
    ]
  })
}
output "mwaa_name" {
  value = aws_mwaa_environment.EMRServerlessAirflow.name
}
output "mwaa_webserver_url" {
  value = aws_mwaa_environment.EMRServerlessAirflow.webserver_url
}
