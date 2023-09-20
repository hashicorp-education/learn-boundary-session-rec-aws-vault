# vault + boundary worker

output "vault_public_ip" {
  description = "ec2 instance public ip address"
  value       = aws_instance.vault.public_ip
}

output "vault_private_ip" {
  description = "ec2 instance private ip address"
  value       = aws_instance.vault.private_ip
}

output "vault_public_dns" {
  description = "ec2 instance public dns address"
  value       = aws_instance.vault.public_dns
}

output "vault_private_key" {
  description = "ssh private key value used to access the ec2 instance"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "host_key_pair_name" {
  description = "key par name used to access the ec2 instances"
  value       = aws_key_pair.boundary-key.key_name
}

output "vault_public_key" {
  description = "ssh public key value used to access the ec2 instance"
  value       = tls_private_key.ssh_key.public_key_openssh
}

output "host_catalog_access_key_id" {
  description = "programmatic access key id for dynamic host catalog testing"
  value       = aws_iam_access_key.host_catalog_plugin.id
  sensitive = true
}

output "host_catalog_secret_access_key" {
  description = "programmatic secret access key for dynamic host catalog testing"
  value       = aws_iam_access_key.host_catalog_plugin.secret
  sensitive = true
}

output "target_instance_ids_map" {
  description = "ec2 instance ids for dynamic host catalog testing"
  value = {
    for _, r in aws_instance.target : r.id => r.public_ip
  }
}

output "target_instance_ids" {
  description = "ec2 instance ids for dynamic host catalog testing"
  value = aws_instance.target.*.id
}

output "target_instance_private_ips" {
  description = "ec2 instance private ips for dynamic host catalog testing"
  value = aws_instance.target.*.private_ip
}

output "target_instance_public_ips" {
  description = "ec2 instance public ips for dynamic host catalog testing"
  value = aws_instance.target.*.public_ip
}

output "target_instance_public_dns" {
  description = "ec2 instance public dns for dynamic host catalog testing"
  value = aws_instance.target.*.public_dns
}

output "target_instance_tags" {
  description = "ec2 instance tags for dynamic host set testing"
  value = {
    for _, r in aws_instance.target : r.id => r.tags
  }
}

# session recording

output "recording_iam_user_names" {
  value = aws_iam_user.user.*.name
}

output "recording_iam_user_arns" {
  value = aws_iam_user.user.*.arn
}

output "recording_iam_access_key_ids" {
  value     = aws_iam_access_key.user_initial_key.*.id
  sensitive = true
}

output "recording_iam_secret_access_keys" {
  value     = aws_iam_access_key.user_initial_key.*.secret
  sensitive = true
}

output "recording_bucket_name" {
  value = aws_s3_bucket.storage_bucket.id
}

output "recording_storage_user_access_key_id" {
  value     = aws_iam_access_key.storage_user_key.id
  sensitive = true
}

output "recording_storage_user_secret_access_key" {
  value     = aws_iam_access_key.storage_user_key.secret
  sensitive = true
}
