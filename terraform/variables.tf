variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name used as prefix for resources"
  type        = string
  default     = "terraform-aws-test"
}

variable "container_port" {
  description = "コンテナ（Rails）が listen するポート"
  type        = number
  default     = 3000
}

variable "domain_name" {
  description = "カスタムドメイン名（例: example.com）。Route 53 で管理するドメインが必要。"
  type        = string
}
