resource "aws_cloudformation_stack" "code-stack" {
  name = "code-stack"
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
    EMRServerlessBucket = aws_s3_bucket.bucket.bucket
  }
  template_body = file("/Users/ccudd/code/emr-serverless-samples/cloudformation/demo/pipeline.yaml")
}
