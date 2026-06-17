# 現在は terraform/ ルートを直接使用。
# Phase 18 以降でモジュール化を進める場合はここに module ブロックを追加する。

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "terraform-aws-test-tfstate-003272771231"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-aws-test-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
