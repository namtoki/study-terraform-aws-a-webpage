# ===== ALB 用 Security Group =====
# インターネットからの HTTP を受ける

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "Allow HTTP from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS は Phase 10（ACM + CloudFront）で追加
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project_name }
}

# ===== ALB 本体（Public Subnet に配置） =====

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  tags = { Project = var.project_name }
}

# ===== Target Group =====
# Fargate(awsvpc) は IP ターゲット

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-app"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/up" # Rails 7.1+ のヘルスチェックエンドポイント
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = { Project = var.project_name }
}

# ===== Listener（HTTP:80 → Target Group） =====

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
