# vault + boundary worker

provider "aws" {
  region = var.AWS_REGION
}

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.47.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.3.0"
    }
  }
}