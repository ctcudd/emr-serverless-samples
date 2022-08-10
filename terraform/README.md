1. terraform init
2. terraform plan --var-file vars.tfvars 
3. terraform apply --var-file vars.tfvars
4. Run Commands:

    ```
    tf_outputs=$(terraform output --json)
    MWAA_ENV=$(echo $tf_outputs | jq -r '.mwaa_name.value')
    HOSTNAME=$(echo $tf_outputs | jq -r '.mwaa_webserver_url.value')
    CLI_TOKEN=$(aws mwaa create-cli-token --name $MWAA_ENV --query CliToken --output text)
   
    while read -r name value;
    do curl --request POST "https://$HOSTNAME/aws_mwaa/cli" \
        --header "Authorization: Bearer $CLI_TOKEN" \
        --header "Content-Type: text/plain" \
        --data-raw "variables set ${name} ${value}"
    done < <(echo $tf_outputs | jq -r 'with_entries(select(.key |startswith("emr")))|to_entries[]|"\(.key) \(.value.value)"')
    ```
