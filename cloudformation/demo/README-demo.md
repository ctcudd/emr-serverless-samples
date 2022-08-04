
1. Deploy dependencies stack
2. Deploy mwaa stack
3. Deploy pipeline stack
4. Populate MWAA vars:
    
    ```
    while read -r name value;
    do curl --request POST "https://$HOSTNAME/aws_mwaa/cli" \
        --header "Authorization: Bearer $CLI_TOKEN" \
        --header "Content-Type: text/plain" \
        --data-raw "variables set ${name} ${value}"
    done < <(aws cloudformation describe-stacks --stack-name mwaa --query "Stacks[0].Outputs[]" | 
       jq '.|{"emr_serverless_application_id": (.[]|select(.OutputKey=="ApplicationId").OutputValue), "emr_serverless_job_role":  (.[]|select(.OutputKey=="JobRoleArn").OutputValue), "emr_serverless_log_bucket": (.[]|select(.OutputKey=="S3Bucket").OutputValue)}' |
       jq -r 'to_entries[] | "\(.key) \(.value)"')

    ```
5. Trigger CodeBuild
6. Navigate to the MWAA UI and start the sbt sample job



