# vault + boundary worker

provider "aws" {
  region = var.AWS_REGION
}

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      version = ">= 4.32.0"
    }
  }
}