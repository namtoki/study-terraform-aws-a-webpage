# 現在は terraform/ ルートを直接使用。
# Phase 18 以降でモジュール化を進める場合はここに module ブロックを追加する。

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
}
