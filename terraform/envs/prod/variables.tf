variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name used as prefix for resources"
  type        = string
  default     = "terraform-aws-prod"
}

variable "domain_name" {
  description = "カスタムドメイン名"
  type        = string
}

variable "alert_email" {
  description = "CloudWatch アラート通知先のメールアドレス"
  type        = string
}

variable "github_org" {
  type    = string
  default = "namtoki"
}

variable "github_repo" {
  type    = string
  default = "study-terraform-aws-a-webpage"
}
