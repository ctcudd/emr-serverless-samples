resource "aws_s3_bucket" "bucket" {
  force_destroy = true
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "airflow_objects" {
  for_each = fileset("${path.module}/../cdk/emr-serverless-with-mwaa/assets/airflow/", "**")
  bucket = aws_s3_bucket.bucket.bucket
  key = each.value
  source = "${path.module}/../cdk/emr-serverless-with-mwaa/assets/airflow/${each.value}"
  etag = filemd5("${path.module}/../cdk/emr-serverless-with-mwaa/assets/airflow/${each.value}")
}


resource "aws_s3_object" "data_objects" {
  for_each = fileset("../cdk/emr-serverless-with-mwaa/assets/data/", "**")
  bucket = aws_s3_bucket.bucket.bucket
  key = each.value
  source = "../cdk/emr-serverless-with-mwaa/assets/data/${each.value}"
  etag = filemd5("../cdk/emr-serverless-with-mwaa/assets/data/${each.value}")
}

resource "aws_s3_object" "source_objects" {
  bucket = aws_s3_bucket.bucket.bucket
  key = "source/sbt-sample.zip"
  source = "../cdk/emr-serverless-with-mwaa/assets/sbt-sample.zip"
  etag = filemd5("../cdk/emr-serverless-with-mwaa/assets/sbt-sample.zip")
}
