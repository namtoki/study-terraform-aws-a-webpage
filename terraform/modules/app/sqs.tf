# ===== SQS Dead Letter Queue =====

resource "aws_sqs_queue" "jobs_dlq" {
  name                      = "${var.project_name}-jobs-dlq"
  message_retention_seconds = 1209600 # 14日
  sqs_managed_sse_enabled   = true

  tags = { Project = var.project_name }
}

# ===== SQS Job Queue =====
# Rails / Sidekiq からジョブを投げるキュー

resource "aws_sqs_queue" "jobs" {
  name                       = "${var.project_name}-jobs"
  visibility_timeout_seconds = 300 # Sidekiq のデフォルトに合わせる
  message_retention_seconds  = 345600 # 4日
  receive_wait_time_seconds  = 20 # Long Polling でコスト削減
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.jobs_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Project = var.project_name }
}

# ===== SQS Queue Policy =====
# ECS タスクロールからの操作のみ許可

resource "aws_sqs_queue_policy" "jobs" {
  queue_url = aws_sqs_queue.jobs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowECSTask"
      Effect = "Allow"
      Principal = {
        AWS = aws_iam_role.ecs_task.arn
      }
      Action = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
      ]
      Resource = aws_sqs_queue.jobs.arn
    }]
  })
}

# ===== ECS Task Role に SQS 権限を付与 =====

resource "aws_iam_role_policy" "ecs_task_sqs" {
  name = "${var.project_name}-ecs-task-sqs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
      ]
      Resource = [
        aws_sqs_queue.jobs.arn,
        aws_sqs_queue.jobs_dlq.arn,
      ]
    }]
  })
}

# ===== SSM Parameter =====
# SQS_JOB_QUEUE_URL を ECS タスクに渡す

resource "aws_ssm_parameter" "sqs_job_queue_url" {
  name  = "/${var.project_name}/sqs/job_queue_url"
  type  = "String"
  value = aws_sqs_queue.jobs.url

  tags = { Project = var.project_name }
}
