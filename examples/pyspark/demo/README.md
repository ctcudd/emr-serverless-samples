* Deploy the [emr_serverless_full_deployment.yaml](../../../cloudformation/emr_serverless_full_deployment.yaml) Cloudformation Template
* Retrieve the stack outputs:
```
export AWS_DEFAULT_REGION=us-east-1
export STACK_NAME=emr-serverless-full
outputs=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs")
export APPLICATION_ID=$(echo $outputs | jq -r '.[]|select(.OutputKey=="ApplicationId").OutputValue')
export S3_BUCKET=$(echo $outputs | jq -r '.[]|select(.OutputKey=="S3Bucket").OutputValue')
export JOB_ROLE_ARN=$(echo $outputs | jq -r '.[]|select(.OutputKey=="JobRoleArn").OutputValue')
```
* Build the python package
```
# Build our custom venv
docker build --output . .
```

* Upload the artifacts to S3
```
aws s3 cp pyspark.tar.gz    s3://${S3_BUCKET}/artifacts/pyspark/
aws s3 cp app.py            s3://${S3_BUCKET}/code/pyspark/
aws s3 cp function.py       s3://${S3_BUCKET}/code/pyspark/
aws s3 cp file.py           s3://${S3_BUCKET}/code/pyspark/
```
* Setup Spark Params
```
ENTRY_POINT="s3://${S3_BUCKET}/code/pyspark/app.py"
LOG_URI="s3://${S3_BUCKET}/logs/"
SPARK_SUBMIT_PARAMS="--conf spark.archives=s3://${S3_BUCKET}/artifacts/pyspark/pyspark.tar.gz#environment "
SPARK_SUBMIT_PARAMS+="--conf spark.emr-serverless.driverEnv.PYSPARK_DRIVER_PYTHON=./environment/bin/python "
SPARK_SUBMIT_PARAMS+="--conf spark.emr-serverless.driverEnv.PYSPARK_PYTHON=./environment/bin/python "
SPARK_SUBMIT_PARAMS+="--conf spark.emr-serverless.executorEnv.PYSPARK_PYTHON=./environment/bin/python "
SPARK_SUBMIT_PARAMS+="--conf spark.submit.pyFiles=s3://${S3_BUCKET}/code/pyspark/function.py "
SPARK_SUBMIT_PARAMS+="--conf spark.fs.s3.maxConnections=100 "
jobDriver=$(jq -cn --arg e $ENTRY_POINT --arg s "${SPARK_SUBMIT_PARAMS}" '{"sparkSubmit":{"entryPoint":$e,"sparkSubmitParameters":$s}}')
configOverrides=$(jq -cn --arg l $LOG_URI '{"monitoringConfiguration":{"s3MonitoringConfiguration":{"logUri":$l}}}')
```
* Submit the job

```
jobDetails=$(aws emr-serverless start-job-run \
    --name custom-python \
    --application-id $APPLICATION_ID \
    --execution-role-arn $JOB_ROLE_ARN \
    --job-driver "${jobDriver}" \
    --configuration-overrides "${configOverrides}")
```

* After job completes (a few mins) view result:
```
JOB_RUN_ID=$(echo $jobDetails | jq -r '.jobRunId')
aws s3 cp s3://${S3_BUCKET}/logs/applications/${APPLICATION_ID}/jobs/${JOB_RUN_ID}/SPARK_DRIVER/stdout.gz - | gunzip
```
