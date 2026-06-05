# ===== ネットワーク =====

# DB を配置する Private Subnet グループ
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db"
  subnet_ids = module.vpc.private_subnets

  tags = { Project = var.project_name }
}

# RDS 用 Security Group（VPC 内からの PostgreSQL のみ許可）
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds"
  description = "Allow PostgreSQL from within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project_name }
}

# ===== RDS PostgreSQL =====

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro" # 無料利用枠相当の最小構成

  allocated_storage     = 20
  max_allocated_storage = 50 # ストレージ自動拡張の上限
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "appdb"
  username = "appuser"
  # パスワードは AWS が Secrets Manager で自動生成・自動ローテーション管理する。
  # tfstate に平文パスワードが残らない。
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false # Phase 16 で Multi-AZ 化
  publicly_accessible    = false # Private Subnet なので外部公開しない

  backup_retention_period = 7
  skip_final_snapshot     = true  # 学習用。本番では false
  deletion_protection     = false # 学習用。本番では true

  tags = { Project = var.project_name }
}

# ===== SSM Parameter Store（非機密の接続情報・設定値） =====
# パスワードは manage_master_user_password が作る Secrets Manager シークレットに入る。
# 接続先（host/port/dbname）は機密ではないので Parameter Store に置く。

resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.project_name}/db/host"
  type  = "String"
  value = aws_db_instance.main.address

  tags = { Project = var.project_name }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.project_name}/db/port"
  type  = "String"
  value = aws_db_instance.main.port

  tags = { Project = var.project_name }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.project_name}/db/name"
  type  = "String"
  value = aws_db_instance.main.db_name

  tags = { Project = var.project_name }
}

resource "aws_ssm_parameter" "rails_env" {
  name  = "/${var.project_name}/rails_env"
  type  = "String"
  value = "production"

  tags = { Project = var.project_name }
}
