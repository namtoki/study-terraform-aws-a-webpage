variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name used as prefix for resources"
  type        = string
  default     = "terraaws-prod"
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

variable "alert_email" {
  description = "CloudWatch アラート通知先のメールアドレス"
  type        = string
}

variable "github_org" {
  description = "GitHub の組織名またはユーザー名（OIDC 信頼ポリシーで使用）"
  type        = string
  default     = "namtoki"
}

variable "github_repo" {
  description = "GitHub リポジトリ名（OIDC 信頼ポリシーで使用）"
  type        = string
  default     = "study-terraform-aws-a-webpage"
}
