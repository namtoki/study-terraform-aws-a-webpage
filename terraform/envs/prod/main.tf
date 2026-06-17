terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "terraform-aws-test-tfstate-003272771231"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-aws-test-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "app" {
  source = "../../modules/app"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  aws_region     = var.aws_region
  project_name   = var.project_name
  container_port = var.container_port
  alert_email    = var.alert_email
  domain_name    = var.domain_name
  github_org     = var.github_org
  github_repo    = var.github_repo
}
