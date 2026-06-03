terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "terraform-aws-test-tfstate"
    key            = "terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-aws-test-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
