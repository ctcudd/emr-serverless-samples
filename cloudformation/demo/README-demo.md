
1. Deploy dependencies stack
2. Deploy mwaa stack
3. Deploy pipeline stack
4. Populate MWAA vars:
    
    ```
    STACK_OUTPUTS=$(aws cloudformation describe-stacks --stack-name mwaa --query "Stacks[0].Outputs[]")
    MWAA_ENV=$(echo $STACK_OUTPUTS | jq -r '.[]|select(.OutputKey=="Mwaa").OutputValue')
    HOSTNAME=$(aws mwaa get-environment --name $MWAA_ENV --query Environment.WebserverUrl --output text)
    CLI_TOKEN=$(aws mwaa create-cli-token --name $MWAA_ENV --query CliToken --output text)

    while read -r name value;
    do curl --request POST "https://$HOSTNAME/aws_mwaa/cli" \
        --header "Authorization: Bearer $CLI_TOKEN" \
        --header "Content-Type: text/plain" \
        --data-raw "variables set ${name} ${value}"
    done < <(echo $STACK_OUTPUTS | 
       jq '.|{"emr_serverless_application_id": (.[]|select(.OutputKey=="ApplicationId").OutputValue), "emr_serverless_job_role":  (.[]|select(.OutputKey=="JobRoleArn").OutputValue), "emr_serverless_log_bucket": (.[]|select(.OutputKey=="S3Bucket").OutputValue)}' |
       jq -r 'to_entries[] | "\(.key) \(.value)"')

    ```
5. Trigger CodeBuild
6. Navigate to the MWAA UI and start job



