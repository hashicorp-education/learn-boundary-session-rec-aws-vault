#!/bin/bash
set -e

function _init {
    username=$(whoami)
    terraform init
    terraform workspace select $username || terraform workspace new $username
    terraform workspace select $username
}

function _validate_private_key {
    workspace=$(terraform workspace show)
    key_pair_name=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.host_key_pair_name.value")
    if [ "$key_pair_name" == "" ]; then
        echo "missing key pair name from terraform state file. please try running make apply."
        exit 1
    fi
    target_address=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.vault_public_dns.value")
    if [ "$target_address" == "" ]; then
        echo "missing ec2 instance public address from terraform state file. please try running make apply."
        exit 1
    fi
    state_key_value=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.vault_private_key.value")
    if [ "$state_key_value" == "" ]; then
        echo "missing private key value from terraform state file. please try running make apply."
        exit 1
    fi
    if [ -e ~/.ssh/$key_pair_name.pem ]; then
        current_key_value=$(cat ~/.ssh/$key_pair_name.pem)
        if [ "${current_key_value}" != "${state_key_value}" ]; then
            rm ~/.ssh/${key_pair_name}.pem
        fi
    fi
    if [ ! -e ~/.ssh/$key_pair_name.pem ]; then
        sh -c "echo \"$state_key_value\" > ~/.ssh/${key_pair_name}.pem"
        chmod 400 ~/.ssh/${key_pair_name}.pem
    fi   
}

function _validate_boundary_login {
    if [ "$BOUNDARY_USERNAME" == "" ]; then
        echo "missing env variable \"BOUNDARY_USERNAME\"."
        exit 1
    fi
    if [ "$BOUNDARY_PASSWORD" == "" ]; then
        echo "missing env variable \"BOUNDARY_PASSWORD\"."
        exit 1
    fi
    if [ "$BOUNDARY_AUTH_METHOD_ID" == "" ]; then
        echo "missing env variable \"BOUNDARY_AUTH_METHOD_ID\"."
        exit 1
    fi
    if [ "$BOUNDARY_ADDR" == "" ]; then
        echo "missing env variable \"BOUNDARY_ADDR\"."
        exit 1
    fi
    boundary authenticate password -auth-method-id $BOUNDARY_AUTH_METHOD_ID -login-name $BOUNDARY_USERNAME -password env://BOUNDARY_PASSWORD
}

function apply {
    pushd infra
    _init
    if [ "$INSTANCE_COUNT" == "" ]; then
        INSTANCE_COUNT=2
    fi
    terraform apply -auto-approve -var="AWS_REGION=${AWS_REGION}" -var="boundary_cluster_id=${BOUNDARY_CLUSTER_ID}" -var="instance_count"=${INSTANCE_COUNT}
    _validate_private_key
    popd
}

function force_apply {
    pushd infra
    _init
    terraform taint aws_instance.vault
    popd
    apply
}

function destroy {
    pushd infra
    _init
    workspace=$(terraform workspace show)
    key_pair_name=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.key_pair_name.value")
    if [ -e ~/.ssh/${key_pair_name}.pem ]; then
        rm ~/.ssh/${key_pair_name}.pem
    fi
    if [ "$INSTANCE_COUNT" == "" ]; then
        INSTANCE_COUNT=2
    fi
    terraform destroy -var="AWS_REGION=${AWS_REGION}" -var="boundary_cluster_id=${BOUNDARY_CLUSTER_ID}" -var="instance_count"=${INSTANCE_COUNT}
    popd
}

function terraform_output {
    pushd infra/
    terraform output
    popd
}

function vault_root_token {
    pushd infra
    _validate_private_key
    workspace=$(terraform workspace show)
    key_pair_name=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.host_key_pair_name.value")
    target_address=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.vault_public_dns.value")
    if [ "$target_address" == "" ]; then
        echo "missing ec2 instance public address from terraform state file. please try running make apply."
        exit 1
    fi
    scp -i ~/.ssh/${key_pair_name}.pem ec2-user@$target_address:/vault/config/credentials ./vault_credentials
    token=$(cat ./vault_credentials | jq -r ".root_token" )
    echo "export VAULT_TOKEN=\"${token}\""
    echo "export VAULT_ADDR=\"http://${target_address}:8200\""
    rm ./vault_credentials
    popd
}

function vault_init {
    pushd infra
    workspace=$(terraform workspace show)
    _validate_private_key
    popd

    pushd vault
    if [ "$VAULT_TOKEN" == ""]; then
        echo "missing env variable: \"VAULT_TOKEN\". please run make vault_token."
        exit 1
    fi
    if [ "$VAULT_ADDR" == ""]; then
        echo "missing env variable: \"VAULT_ADDR\". please run make vault_token."
        exit 1
    fi
    vault login $VAULT_TOKEN
    vault policy write boundary-controller boundary-controller-policy.hcl
    vault policy write kv-read kv-read.hcl
    vault secrets disable secret/
    vault secrets enable -path=secret kv-v2
    vault kv delete "secret/ssh_host"
    private_key_path=$(echo ~/.ssh/$key_pair_name.pem)
    vault kv put "secret/ssh_host" username="ec2-user" private_key=@$private_key_path
    client_token=$(vault token create \
        -no-default-policy=true \
        -policy="boundary-controller" \
        -policy="kv-read" \
        -orphan=true \
        -period=20m \
        -renewable=true \
        -format=json | jq -r ".auth.client_token")
    echo "export VAULT_CRED_STORE_TOKEN=\"${client_token}\""
    popd
}

function vault_connect {
    pushd infra
    _init
    _validate_private_key
    workspace=$(terraform workspace show)
    key_pair_name=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.host_key_pair_name.value")
    target_address=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.vault_public_dns.value")
    ssh -i ~/.ssh/${key_pair_name}.pem "ec2-user@$target_address"
    popd
}

function vault_worker_token {
    _validate_boundary_login
    pushd infra
    _validate_private_key
    if [ "$BOUNDARY_ADDR" == "" ]; then
        echo "missing env variable: \"BOUNDARY_ADDR\""
        exit 1
    fi
    workspace=$(terraform workspace show)
    target_address=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.vault_public_dns.value")
    scp -i ~/.ssh/${key_pair_name}.pem ec2-user@$target_address:/boundary-worker/config/worker_auth_token ./worker_auth_token
    token=$(cat ./worker_auth_token)
    echo "BOUNDARY_WORKER_TOKEN=\"$token\""
    rm ./worker_auth_token
    boundary workers create worker-led -name vault-worker -worker-generated-auth-token=$token 
    popd
}

function host_worker_tokens {
    _validate_boundary_login
    pushd infra
    _validate_private_key
    if [ "$BOUNDARY_ADDR" == "" ]; then
        echo "missing env variable: \"BOUNDARY_ADDR\""
        exit 1
    fi
    if [ "$INSTANCE_COUNT" == "" ]; then
        INSTANCE_COUNT=2
    fi
    workspace=$(terraform workspace show)
    for ((i=0; i<$INSTANCE_COUNT; i++));
    do
      WORKER_COUNT=$(($i+1))
      target_address=$(jq -r ".outputs.target_instance_public_dns.value[$i]" "./terraform.tfstate.d/${workspace}/terraform.tfstate")
      scp -i ~/.ssh/${key_pair_name}.pem ec2-user@$target_address:/boundary-worker/config/worker_auth_token ./worker_auth_token
      token=$(cat ./worker_auth_token)
      echo "export BOUNDARY_WORKER_${WORKER_COUNT}_TOKEN=\"$token\""
      rm ./worker_auth_token
      boundary workers create worker-led -name "aws-worker-${WORKER_COUNT}" -worker-generated-auth-token=$token
    done
    popd
}

function dynamic_host_catalog {
    _validate_boundary_login
    if [ "$PROJECT_ID" == "" ]; then
        echo "missing arg PROJECT_ID."
        exit 1
    fi
    pushd infra
    workspace=$(terraform workspace show)
    access_key_id=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.target_access_key_id.value")
    if [ "$access_key_id" == "" ]; then
        echo "missing target_access_key_id from terraform state file. please try running make apply."
        exit 1
    fi
    secret_access_key=$(cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.target_secret_access_key.value")
    if [ "$secret_access_key" == "" ]; then
        echo "missing target_secret_access_key from terraform state file. please try running make apply."
        exit 1
    fi
    echo "Dynamic Host Catalog AWS Info:"
    echo "Instance IDs:"
    cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.target_instance_ids.value"
    echo "Public IPs:"
    cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.target_instance_public_ips.value"
    echo "Private IPs:"
    cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.target_instance_private_ips.value"
    echo "Public DNS:"
    cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.target_instance_public_dns.value"
    echo "Tags:"
    cat "./terraform.tfstate.d/${workspace}/terraform.tfstate" | jq -r ".outputs.target_instance_tags.value"
    dhc_id=$(boundary host-catalogs create plugin \
        -scope-id $PROJECT_ID \
        -plugin-name aws \
        -attr disable_credential_rotation=true \
        -attr region=$AWS_REGION \
        -secret access_key_id=$access_key_id \
        -secret secret_access_key=$secret_access_key \
        -format json | jq -r ".item.id")
    echo "export HOST_CATALOG_ID=\"${dhc_id}\""
    popd
}