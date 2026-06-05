# ===== ECS タスク用 Security Group =====
# ALB からのトラフィックのみ許可

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs"
  description = "Allow traffic from ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # ← ALB の SG を送信元に
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project_name }
}

# ===== CloudWatch Logs =====

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-app"
  retention_in_days = 14

  tags = { Project = var.project_name }
}

# ===== IAM: Execution Role（ECS Agent 用） =====
# ECR pull / CloudWatch Logs / Secrets・SSM の取得

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Secrets Manager / SSM から環境変数を注入するための追加権限
data "aws_iam_policy_document" "ecs_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.main.master_user_secret[0].secret_arn]
  }
  statement {
    actions = ["ssm:GetParameters"]
    resources = [
      aws_ssm_parameter.db_host.arn,
      aws_ssm_parameter.db_port.arn,
      aws_ssm_parameter.db_name.arn,
      aws_ssm_parameter.rails_env.arn,
    ]
  }
}

resource "aws_iam_role_policy" "ecs_secrets" {
  name   = "${var.project_name}-ecs-secrets"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.ecs_secrets.json
}

# ===== IAM: Task Role（アプリ自身が使う） =====
# 今は最小（必要に応じて S3 等の権限を後で付与）

resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = { Project = var.project_name }
}

# ===== ECS Cluster =====

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Project = var.project_name }
}

# ===== Task Definition（Fargate） =====

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true

      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]

      # 非機密の接続情報・設定は SSM Parameter Store から
      secrets = [
        { name = "DB_HOST", valueFrom = aws_ssm_parameter.db_host.arn },
        { name = "DB_PORT", valueFrom = aws_ssm_parameter.db_port.arn },
        { name = "DB_NAME", valueFrom = aws_ssm_parameter.db_name.arn },
        { name = "RAILS_ENV", valueFrom = aws_ssm_parameter.rails_env.arn },
        # 認証情報は AWS 管理の Secrets Manager シークレットから JSON キーで取り出す
        { name = "DB_USERNAME", valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:username::" },
        { name = "DB_PASSWORD", valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:password::" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = { Project = var.project_name }
}

# ===== ECS Service =====

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false # Private Subnet。ECR pull は NAT Gateway 経由
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  # Listener が出来てから Service を作る
  depends_on = [aws_lb_listener.http]

  tags = { Project = var.project_name }
}
