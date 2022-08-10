data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_emr_studio" "example" {
  auth_mode                   = "IAM"
  default_s3_location         = "s3://${aws_s3_bucket.bucket.bucket}"
  engine_security_group_id    = aws_security_group.EMRStudioEngineSG.id
  name                        = "EMRServerlessAdmin"
  service_role                = aws_iam_role.EMRStudioServiceRole.arn
  subnet_ids                  = local.private_subnets
  vpc_id                      = aws_vpc.Main.id
  workspace_security_group_id = aws_security_group.EMRWorkspaceEngineSG.id
}

resource "aws_security_group" "EMRStudioEngineSG" {
  vpc_id = aws_vpc.Main.id
  description = "EMRStudio/EMRStudioEngine"
  tags = {
    for-use-with-amazon-emr-managed-policies = true
  }
}
resource "aws_security_group_rule" "EMRStudioEngineSG-Ingress" {
  type        = "ingress"
  description = "Allow inbound traffic to EngineSecurityGroup ( from notebook to cluster for port 18888 )"
  protocol    = "tcp"
  to_port     = 18888
  from_port   = 18888
  security_group_id = aws_security_group.EMRStudioEngineSG.id
  source_security_group_id = aws_security_group.EMRWorkspaceEngineSG.id
}
resource "aws_security_group_rule" "EMRStudioEngineSG-IngressSelf" {
  type        = "ingress"
  description = "Allow inbound traffic to EngineSecurityGroup ( from notebook to cluster for port 18888 )"
  protocol    = "tcp"
  to_port     = 18888
  from_port   = 18888
  security_group_id = aws_security_group.EMRStudioEngineSG.id
  self = true
}

resource "aws_security_group_rule" "EMRStudioEngineSG-Egress" {
  type        = "egress"
  description = "Allow all outbound traffic by default"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.EMRWorkspaceEngineSG.id
}

resource "aws_security_group" "EMRWorkspaceEngineSG" {
  vpc_id = aws_vpc.Main.id
  egress {
    description = "Allow outbound git access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow outbound traffic from WorkspaceSecurityGroup ( from notebook to cluster for port 18888 )"
    from_port = 18888
    protocol  = "tcp"
    to_port   = 18888
    security_groups = [aws_security_group.EMRStudioEngineSG.id]
  }
  description = "EMRStudio/EMRWorkspaceEngine"
  tags = {
    for-use-with-amazon-emr-managed-policies = true
  }
}


#resource "aws_iam_service_linked_role" "EMRStudioServiceRole" {
#  aws_service_name = "elasticmapreduce.amazonaws.com"
#}

resource "aws_iam_role" "EMRStudioServiceRole" {
  name = "EMRStudioServiceRole"
  path = "/service-role/"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": ["elasticmapreduce.amazonaws.com"]
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "EMRStudioServiceRoleAttach" {
  role       = aws_iam_role.EMRStudioServiceRole.name
  policy_arn = aws_iam_policy.EMRStudioServiceRolePolicy.arn
}

resource "aws_iam_policy" "EMRStudioServiceRolePolicy" {

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowEMRReadOnlyActions"
        Action = [
          "elasticmapreduce:DescribeCluster",
          "elasticmapreduce:ListInstances",
          "elasticmapreduce:ListSteps"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowEC2ENIActionsWithEMRTags"
        Action = [
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      },
      {
        Sid = "AllowEC2ENIAttributeAction"
        Action = [
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*"
        ]
      },
      {
        Sid = "AllowEC2SecurityGroupActionsWithEMRTags"
        Action = [
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowDefaultEC2SecurityGroupsCreationWithEMRTags"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowDefaultEC2SecurityGroupsCreationInVPCWithEMRTags"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowAddingEMRTagsDuringDefaultSecurityGroupCreation"
        Action = [
          "ec2:CreateTags"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowEC2ENICreationWithEMRTags"
        Action = [
          "ec2:CreateNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowEC2ENICreationInSubnetAndSecurityGroupWithEMRTags"
        Action = [
          "ec2:CreateNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowAddingTagsDuringEC2ENICreation"
        Action = [
          "ec2:CreateTags"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateNetworkInterface"
          }
        }
      },
      {
        Sid = "AllowEC2ReadOnlyActions"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVpcs"
        ]
        Effect   = "Allow"
        Resource = [
          "*"
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateNetworkInterface"
          }
        }
      },
      {
        Sid = "AllowSecretsManagerReadOnlyActionsWithEMRTags"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },
      {
        Sid = "AllowS3ObjectActions"
        Action = [
          "s3:DeleteObject",
          "s3:GetEncryptionConfiguration",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::*"
        ]
      },
    ]
  })
}
