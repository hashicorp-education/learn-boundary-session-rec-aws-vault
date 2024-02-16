# vault + boundary worker

data "aws_region" "current" {}
data "aws_ami" "amazon" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "vault" {
  ami                         = data.aws_ami.amazon.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.boundary-key.key_name
  vpc_security_group_ids      = [aws_security_group.vault.id]
  subnet_id                   = aws_subnet.vault_subnet.id
  iam_instance_profile        = aws_iam_instance_profile.vault.id

  root_block_device {
    volume_type = "gp2"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "../scripts/vault"
    destination = "/home/ec2-user/vault"
  }

  provisioner "file" {
    source      = "../scripts/boundary-worker"
    destination = "/home/ec2-user/boundary-worker"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"export PRIVATE_IP=${aws_instance.vault.private_ip}\" >> ~/.bashrc",
      "echo \"export PUBLIC_IP=${aws_instance.vault.public_ip}\" >> ~/.bashrc",
      "echo \"export PUBLIC_DNS=${aws_instance.vault.public_dns}\" >> ~/.bashrc",
      "echo \"export KMS_KEY_ID=${aws_kms_key.vault.key_id}\" >> ~/.bashrc",
      "echo \"export REGION=${data.aws_region.current.name}\" >> ~/.bashrc",
      "echo \"export CLUSTER_ID=${var.boundary_cluster_id}\" >> ~/.bashrc"
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "../scripts/vault_init.sh",
      "../scripts/vault_worker_init.sh"
    ]
  }

  tags = local.vault_tags
}

resource "random_integer" "tag" {
  count = var.instance_count
  min   = 0
  max   = length(local.host_catalog_plugin_tags)-1
  keepers = {
    always_recreate = uuid()
  }
}

resource "aws_instance" "target" {
  count                       = var.instance_count
  ami                         = data.aws_ami.amazon.id
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.target_subnet[count.index].id
  key_name                    = aws_key_pair.boundary-key.key_name
  vpc_security_group_ids      = [aws_security_group.host_catalog_plugin[count.index].id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "../scripts/boundary-worker"
    destination = "/home/ec2-user/boundary-worker"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"export PRIVATE_IP=${self.private_ip}\" >> ~/.bashrc",
      "echo \"export PUBLIC_IP=${self.public_ip}\" >> ~/.bashrc",
      "echo \"export PUBLIC_DNS=${self.public_dns}\" >> ~/.bashrc",
      "echo \"export REGION=${data.aws_region.current.name}\" >> ~/.bashrc",
      "echo \"export CLUSTER_ID=${var.boundary_cluster_id}\" >> ~/.bashrc",
      "echo \"export WORKER_COUNT=${count.index + 1}\" >> ~/.bashrc",
      "echo \"export WORKER_ENV=${local.host_catalog_plugin_tags[count.index].env}\" >> ~/.bashrc"
    ]
  }

  provisioner "remote-exec" {
    script = "../scripts/target_worker_init.sh"
  }

  tags = merge({
    "Name" : "target-${local.deployment_name}-%03d, count.index + 1"
    "User" : local.deployment_name
  }, local.host_catalog_plugin_tags[count.index])
}