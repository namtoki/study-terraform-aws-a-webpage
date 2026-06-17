# ===== OpenSearch Secrets Manager =====
# マスター認証情報を Secrets Manager で管理

resource "aws_secretsmanager_secret" "opensearch_master" {
  name                    = "${var.project_name}/opensearch/master"
  recovery_window_in_days = 0 # 学習用: 即削除可能

  tags = { Project = var.project_name }
}

resource "aws_secretsmanager_secret_version" "opensearch_master" {
  secret_id = aws_secretsmanager_secret.opensearch_master.id
  secret_string = jsonencode({
    username = "admin"
    password = "Admin@${var.project_name}1!" # 本番では tfvars で外部注入
  })
}

# ===== Security Group =====
# ECS タスクからの HTTPS(443) のみ許可

resource "aws_security_group" "opensearch" {
  name        = "${var.project_name}-opensearch"
  description = "Allow HTTPS from ECS only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "From ECS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project_name }
}

# ===== OpenSearch Domain =====

resource "aws_opensearch_domain" "main" {
  domain_name    = var.project_name
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 10
  }

  vpc_options {
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = jsondecode(aws_secretsmanager_secret_version.opensearch_master.secret_string)["username"]
      master_user_password = jsondecode(aws_secretsmanager_secret_version.opensearch_master.secret_string)["password"]
    }
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = aws_iam_role.ecs_task.arn }
      Action    = "es:*"
      Resource  = "arn:aws:es:${var.aws_region}:*:domain/${var.project_name}/*"
    }]
  })

  tags = { Project = var.project_name }
}

# ===== ECS Task Role に OpenSearch 権限を付与 =====

resource "aws_iam_role_policy" "ecs_task_opensearch" {
  name = "${var.project_name}-ecs-task-opensearch"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "es:ESHttpGet",
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpDelete",
      ]
      Resource = "${aws_opensearch_domain.main.arn}/*"
    }]
  })
}

# ===== SSM Parameter =====
# OPENSEARCH_URL を ECS タスクに渡す

resource "aws_ssm_parameter" "opensearch_url" {
  name  = "/${var.project_name}/opensearch/url"
  type  = "String"
  value = "https://${aws_opensearch_domain.main.endpoint}"

  tags = { Project = var.project_name }
}
