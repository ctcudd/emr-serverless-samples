# We create an IAM role for job execution
# By default, it can read and write our bucket
# MWAA needs to PassRole to it
resource "aws_iam_role" "emr-serverless-job-role" {
  name               = "emr-serverless-job-role"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json # (not shown)
  inline_policy {
    name   = "s3-access-policy"
    policy = data.aws_iam_policy_document.s3-access-policy.json
  }
  inline_policy {
    name   = "glue-access-policy"
    policy = data.aws_iam_policy_document.glue-access-policy.json
  }
}

data "aws_iam_policy_document" "s3-access-policy" {
  statement {
    actions   = ["s3:GetObject","s3:ListBucket"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions   = ["s3:PutObject","s3:DeleteObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}

data "aws_iam_policy_document" "glue-access-policy" {
  statement {
    actions   = ["glue:GetDatabase",
      "glue:GetDataBases",
      "glue:CreateTable",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:GetUserDefinedFunctions"]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["emr-serverless.amazonaws.com"]
    }
  }
}
