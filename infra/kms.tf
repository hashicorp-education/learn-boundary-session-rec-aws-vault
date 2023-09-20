# vault + boundary worker

resource "aws_kms_key" "vault" {
  description = "${terraform.workspace} vault unseal key"
  tags        = local.vault_tags
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${terraform.workspace}-vault-unseal-key"
  target_key_id = aws_kms_key.vault.key_id
}