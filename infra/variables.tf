# vault + boundary worker

variable "AWS_REGION" {
    type = string
    default     = "us-east-1"
}

variable "instance_count" {
    description = "number of ec2 instances created for testing dynamic host catalog."
    default     = 2
    # the default is overwritten by the INSTANCE_COUNT variable defined in scripts/setup.sh
}

variable "boundary_cluster_id" {
    description = "boundary cluster id used by the self managed worker"
    validation {
        condition     = can(regex("^[0-9a-fA-F]{8}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{4}\\b-[0-9a-fA-F]{12}$", var.boundary_cluster_id))
        error_message = "The boundery cluster id value must be a valid uuid."
    }
}

locals {
    deployment_name = split(":", data.aws_caller_identity.current.user_id)[1]
    vault_tags = {
        Name      = "boundary-vault"
        env       = "vault-dev"
        workspace = terraform.workspace
    }
    host_catalog_plugin_tags = [{
        Name  = "boundary-host-1"
        env       = "dev"
        workspace = terraform.workspace
    }, {
        Name  = "boundary-host-2"
        env       = "prod"
        workspace = terraform.workspace
    }, {
        Name  = "boundary-host-3"
        env       = "dev"
        workspace = terraform.workspace
    }, {
        Name  = "boundary-host-4"
        env       = "prod"
        workspace = terraform.workspace
    }, {
        Name  = "boundary-host-5"
        env       = "prod"
        workspace = terraform.workspace
    }]
}

# session recording

data "aws_caller_identity" "current" {}

variable "iam_user_count" {
  default = 2
}