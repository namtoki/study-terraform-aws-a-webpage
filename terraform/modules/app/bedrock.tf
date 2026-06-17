# ===== ECS Task Role に Bedrock 権限を付与 =====
# Bedrock 自体はマネージドサービスのため Terraform リソースは IAM のみ

resource "aws_iam_role_policy" "ecs_task_bedrock" {
  name = "${var.project_name}-ecs-task-bedrock"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeFoundationModels"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
          "arn:aws:bedrock:*::foundation-model/amazon.titan-embed-text-v1",
        ]
      },
      {
        Sid      = "ListFoundationModels"
        Effect   = "Allow"
        Action   = ["bedrock:ListFoundationModels"]
        Resource = "*"
      },
    ]
  })
}

# ===== SSM Parameter =====
# BEDROCK_REGION を ECS タスクに渡す

resource "aws_ssm_parameter" "bedrock_region" {
  name  = "/${var.project_name}/bedrock/region"
  type  = "String"
  value = var.aws_region

  tags = { Project = var.project_name }
}
