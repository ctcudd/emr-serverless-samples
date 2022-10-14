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
ENTRY_POINT_ARGS="${S3_BUCKET}"
LOG_URI="s3://${S3_BUCKET}/logs/"
SPARK_SUBMIT_PARAMS="--conf spark.archives=s3://${S3_BUCKET}/artifacts/pyspark/pyspark.tar.gz#environment "
SPARK_SUBMIT_PARAMS+="--conf spark.submit.pyFiles=s3://${S3_BUCKET}/code/pyspark/function.py "
SPARK_SUBMIT_PARAMS+="--conf spark.emr-serverless.driverEnv.PYSPARK_DRIVER_PYTHON=./environment/bin/python "
SPARK_SUBMIT_PARAMS+="--conf spark.emr-serverless.driverEnv.PYSPARK_PYTHON=./environment/bin/python "
SPARK_SUBMIT_PARAMS+="--conf spark.executorEnv.PYSPARK_PYTHON=./environment/bin/python "
jobDriver=$(jq -cn --arg e "${ENTRY_POINT}" --arg a "${ENTRY_POINT_ARGS}" --arg s "${SPARK_SUBMIT_PARAMS}" '{"sparkSubmit":{"entryPoint":$e,"sparkSubmitParameters":$s,"entryPointArguments":[$a]}}')
configOverrides=$(jq -cn --arg l "${LOG_URI}" '{"monitoringConfiguration":{"s3MonitoringConfiguration":{"logUri":$l}}}')
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

---
Python Development

```shell
# run latest amazn linux
docker run -it public.ecr.aws/amazonlinux/amazonlinux bash

# basic config
yum -y update && yum install -y python3 sudo which shadow-utils && useradd ec2-user
sudo -iu ec2-user

# python version and location
which python
# returns the first found in your $PATH

# watch out for python2
python --version
# python3 version must match EMR Serverless: https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/using-python-libraries.html
python3 --version

# where is pip???
pip --version
#bash: pip: command not found

# use pip3 instead
pip3 --version
python3 -m pip --version

# where does pip install?
python3 -m pip install requests
pip3 install --user boto
pip3 install pandas -t .

# it depends ...
pip3 show requests
pip3 show boto
pip3 show pandas

# create a virtual env to isolate a project dependencies
python3 -m venv my_virtual_env

# activate the virtual env 
source my_virtual_env/bin/activate

# notice the changes to python/pip 
which pip pip3 python python3

# pip will now install dependencies within the virtual env
pip install pandas
pip show pandas

# deactivate the virtual env
deactivate



```


---

Additional Links:
* https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/using-python-libraries.html
* https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/using-python.html
* https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/jobs-spark.html
* https://spark.apache.org/docs/latest/api/python/user_guide/python_packaging.html
