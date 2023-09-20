# provider "boundary" {
#   addr                   = var.BOUNDARY_ADDR
#   auth_method_id         = var.BOUNDARY_AUTH_METHOD_ID
#   auth_method_login_name = var.BOUNDARY_USERNAME
#   auth_method_password   = var.BOUNDARY_PASSWORD
# }

# terraform {
#   required_version = ">= 1.3.0"
#   required_providers {
#     boundary = {
#       source  = "hashicorp/boundary",
#       version = ">= 1.1.9"
#     }
#   }
# }

# variable "BOUNDARY_ADDR" {
#     type = string
# }

# variable "BOUNDARY_AUTH_METHOD_ID" {
#     type = string
# }

# variable "BOUNDARY_USERNAME" {
#     type = string
# }

# variable "BOUNDARY_PASSWORD" {
#     type = string
# }

# variable "HOST_CATALOG_ACCESS_KEY_ID" {
#     type = string
# }

# variable "HOST_CATALOG_SECRET_ACCESS_KEY" {
#     type = string
# }

# variable "AWS_REGION" {
#     type = string
# }

# variable "VAULT_ADDR" {
#     type = string
# }

# variable "VAULT_CRED_STORE_TOKEN" {
#     type = string
# }

# variable "recording_bucket_name" {
#     type = string
# }

# variable "recording_storage_user_access_key_id" {
#     type = string
# }

# variable "recording_storage_user_secret_access_key" {
#     type = string
# }

# resource "boundary_scope" "global" {
#   global_scope = true
#   scope_id     = "global"
# }

# resource "boundary_scope" "org" {
#   name        = "ssh-recording-org-5"
#   description = "SSH test org"
#   scope_id    = boundary_scope.global.id
#   auto_create_admin_role   = true
#   auto_create_default_role = true
# }

# resource "boundary_auth_method_password" "password" {
#   name        = "org_password_auth"
#   description = "Password auth method for org"
#   type        = "password"
#   scope_id    = boundary_scope.org.id
# }

# resource "boundary_scope" "ssh-recording-project" {
#   name                   = "ssh-recording-project"
#   description            = "Secure Socket Handling recordings"
#   scope_id               = boundary_scope.org.id
#   auto_create_admin_role = true
# }

# resource "boundary_host_catalog_plugin" "aws_hosts" {
#   name            = "aws-recording-catalog"
#   description     = "AWS session recording host catalog"
#   scope_id        = boundary_scope.ssh-recording-project.id
#   plugin_name     = "aws"
#   attributes_json = jsonencode({
#     "region"=var.AWS_REGION,
#     "disable_credential_rotation"=true,
#   })
#   secrets_json = jsonencode({
#     "access_key_id"     = var.HOST_CATALOG_ACCESS_KEY_ID,
#     "secret_access_key" = var.HOST_CATALOG_SECRET_ACCESS_KEY
#   })
# }

# resource "boundary_host_set_plugin" "dev" {
#   name            = "dev_host_set"
#   host_catalog_id = boundary_host_catalog_plugin.aws_hosts.id
#   attributes_json = jsonencode({ "filters" = ["tag:env=dev"] })
# }

# resource "boundary_host_set_plugin" "prod" {
#   name            = "prod_host_set"
#   host_catalog_id = boundary_host_catalog_plugin.aws_hosts.id
#   attributes_json = jsonencode({ "filters" = ["tag:env=prod"] })
# }

# resource "boundary_credential_store_vault" "vault_host_cred_store" {
#   name        = "Vault AWS Host Credentials"
#   address     = var.VAULT_ADDR
#   token       = var.VAULT_CRED_STORE_TOKEN
#   scope_id    = boundary_scope.ssh-recording-project.id
# }

# resource "boundary_credential_library_vault" "vault_host_cred_library" {
#   name                = "Vault AWS Host Cred Library"
#   credential_store_id = boundary_credential_store_vault.vault_host_cred_store.id
#   credential_type     = "ssh_private_key"
#   path                = "secret/data/ssh_host"
#   http_method         = "GET"
# }

# # # Boundary storage bucket, may also be configured via UI or CLI

# # resource "boundary_storage_bucket" "aws_bucket" {
# #   name            = "ssh-test-bucket-2"
# #   description     = "SSH session recording test bucket"
# #   scope_id        = boundary_scope.org.id
# #   plugin_name     = "aws"
# #   bucket_name     = var.recording_bucket_name
# #   attributes_json = jsonencode({
# #     "region" = "${var.AWS_REGION}",
# #     "disable_credential_rotation" = true
# #   })

# #   secrets_json = jsonencode({
# #     "access_key_id"     = "${var.recording_storage_user_access_key_id}",
# #     "secret_access_key" = "${var.recording_storage_user_secret_access_key}"
# #   })
  
# #   worker_filter = "\"s3\" in \"/tags/type\""
# # }

# # # SSH target config, may also be configured via UI or CLI

# # resource "boundary_target" "ssh" {
# #   name         = "dev-recording-target"
# #   description  = "SSH target"
# #   type         = "ssh"
# #   default_port = "22"
# #   scope_id     = boundary_scope.ssh-recording-project.id
# #   egress_worker_filter     = "\"dev-worker\" in \"/tags/type\""
# #   host_source_ids = [
# #     boundary_host_set_plugin.dev.id
# #   ]
# #   injected_application_credential_source_ids = [
# #     boundary_credential_library_vault.vault_host_cred_library.id
# #   ]
# #   enable_session_recording = true
# #   storage_bucket_id        = boundary_storage_bucket.aws_bucket.id
# # }