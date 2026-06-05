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
