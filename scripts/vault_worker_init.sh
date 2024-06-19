#!/bin/bash
set -e

sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install boundary-enterprise

boundary version

sudo mkdir /boundary-worker
sudo mkdir /boundary-worker/config
sudo mkdir /boundary-worker/logs
sudo mkdir -p /boundary-worker/auth/nodecreds
sudo chmod -R a+rwx /boundary-worker

cat > /home/ec2-user/config.hcl <<- EOF
disable_mlock = true
hcp_boundary_cluster_id = "${CLUSTER_ID}"

listener "tcp" {
  address     = "0.0.0.0:9202"
  purpose     = "proxy"
  tls_disable = true
}

worker {
  public_addr = "${PUBLIC_IP}:9202"
  auth_storage_path = "/boundary-worker/auth"
  recording_storage_path = "/tmp/boundary/worker-recordings"
  recording_storage_minimum_available_capacity = "100MB"
  tags {
    type = ["worker", "vault", "s3"]
  }
}
EOF

sudo mv /home/ec2-user/config.hcl /boundary-worker/config/config.hcl
cat /boundary-worker/config/config.hcl

sudo mv /home/ec2-user/boundary-worker /etc/init.d/boundary-worker
sudo chmod 755 /etc/init.d/boundary-worker
sudo service boundary-worker start
sleep 5

worker_auth=$(head -n 15 /boundary-worker/logs/log.out | grep "Worker Auth Registration Request:")
echo ${worker_auth:36} > /boundary-worker/config/worker_auth_token
