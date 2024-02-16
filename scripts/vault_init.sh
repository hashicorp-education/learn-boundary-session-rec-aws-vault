#!/bin/bash
set -e

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install vault

sudo mkdir /vault
sudo mkdir /vault/data
sudo mkdir /vault/config
sudo mkdir /vault/tls
sudo mkdir /vault/logs
sudo chmod -R a+rwx /vault

cat > /home/ec2-user/config.hcl <<- EOF
storage "raft" {
  path    = "/vault/data"
  node_id = "node_0"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = "true"
}

# listener for private network
listener "tcp" {
  address         = "${PRIVATE_IP}:8200"
  cluster_address = "${PRIVATE_IP}:8201"
  tls_disable     = "true"
}

# auto unseal the vault using aws kms
seal "awskms" {
  region     = "${REGION}"
  kms_key_id = "${KMS_KEY_ID}"
}

api_addr     = "http://${PUBLIC_DNS}"
cluster_addr = "http://${PUBLIC_DNS}:8201"
ui           = true
EOF
sudo mv /home/ec2-user/config.hcl /vault/config/config.hcl
cat /vault/config/config.hcl

sudo mv /home/ec2-user/vault /etc/systemd/system/vault.service
sudo chmod 755 /etc/systemd/system/vault.service
sudo systemctl start vault
sleep 5

export VAULT_ADDR="http://127.0.0.1:8200"
export AWS_DEFAULT_REGION="${REGION}"
vault operator init -format json > /home/ec2-user/credentials
sudo mv /home/ec2-user/credentials /vault/config/credentials
cat /vault/config/credentials
vault status