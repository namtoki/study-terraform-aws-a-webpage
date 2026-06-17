# ===== ElastiCache Subnet Group =====
# Redis を Private Subnet に配置

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis"
  subnet_ids = module.vpc.private_subnets

  tags = { Project = var.project_name }
}

# ===== Security Group =====
# ECS タスクからの Redis(6379) のみ許可

resource "aws_security_group" "elasticache" {
  name        = "${var.project_name}-elasticache"
  description = "Allow Redis from ECS only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "From ECS"
    from_port       = 6379
    to_port         = 6379
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

# ===== Redis Replication Group =====
# シングルノード構成（学習用）
# num_cache_clusters = 1 + automatic_failover_enabled = false でシングルノード

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis for Rails session and Sidekiq"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t4g.micro"

  num_cache_clusters         = 1
  automatic_failover_enabled = false # シングルノードは false 必須
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]

  at_rest_encryption_enabled = true  # 保存データの暗号化
  transit_encryption_enabled = false # true にすると auth_token が必要。学習用は false

  tags = { Project = var.project_name }
}

# ===== SSM Parameter =====
# REDIS_URL を ECS タスクに渡す

resource "aws_ssm_parameter" "redis_url" {
  name  = "/${var.project_name}/redis/url"
  type  = "String"
  value = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379/0"

  tags = { Project = var.project_name }
}
