# vault + boundary worker

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "boundary-key" {
  key_name   = "${terraform.workspace}-host-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
  tags       = local.vault_tags
}