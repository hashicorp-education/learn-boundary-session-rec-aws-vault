# vault + boundary worker

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "vault" {
  name        = "${terraform.workspace}-boundary-vault-env"
  description = "testing self hosted vault instance against boundary hcp"
  vpc_id      = aws_vpc.vault_vpc.id
  tags        = local.vault_tags
}

resource "aws_security_group_rule" "allow_outgoing_traffic" {
  type              = "egress"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  security_group_id = aws_security_group.vault.id
}

resource "aws_security_group_rule" "incoming_ssh" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.vault.id
}

resource "aws_security_group_rule" "incoming_vault_traffic" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8200
  to_port           = 8201
  security_group_id = aws_security_group.vault.id
}

resource "aws_security_group_rule" "incoming_boundary_traffic" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9202
  to_port           = 9202
  security_group_id = aws_security_group.vault.id
}

resource "aws_security_group_rule" "incoming_http_traffic" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.vault.id
}

resource "aws_security_group" "host_catalog_plugin" {
  count       = var.instance_count
  name        = "${terraform.workspace}-host-catalog-plugin"
  description = "testing dynamic host catalog plugin"
  vpc_id      = aws_vpc.target_vpc[count.index].id
  tags = {
    Name = "${format("target-sg-${local.deployment_name}-%03d", count.index + 1)}",
    User = "${local.deployment_name}"
  }
}

resource "aws_security_group_rule" "dhc_allow_outgoing_traffic" {
  count             = var.instance_count
  type              = "egress"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  security_group_id = aws_security_group.host_catalog_plugin[count.index].id
}

resource "aws_security_group_rule" "dhc_incoming_ssh" {
  count             = var.instance_count
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.host_catalog_plugin[count.index].id
}

resource "aws_security_group_rule" "dhc_incoming_boundary_traffic" {
  count             = var.instance_count
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9202
  to_port           = 9202
  security_group_id = aws_security_group.host_catalog_plugin[count.index].id
}

resource "aws_security_group_rule" "dhc_incoming_http_traffic" {
  count             = var.instance_count
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.host_catalog_plugin[count.index].id
}

# session recording

resource "aws_security_group" "target_security_group" {
  count  = var.instance_count
  vpc_id = aws_vpc.target_vpc[count.index].id
  tags = {
    Name = "${format("target-sg-${local.deployment_name}-%03d", count.index + 1)}",
    User = "${local.deployment_name}"
  }
}

resource "aws_security_group_rule" "security_group_ssh_in" {
  count             = var.instance_count
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.target_security_group[count.index].id
}
