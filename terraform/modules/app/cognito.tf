data "aws_caller_identity" "current" {}

# ===== User Pool（ユーザーディレクトリ） =====

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-users"

  # メールアドレスをユーザー名（ログイン ID）にする
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  # パスワード忘れの復旧はメール経由
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # 検証コードをメール送信（学習用は Cognito 標準送信＝1日50通まで。本番は SES 連携）
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # MFA は学習用に OFF（本番は OPTIONAL 以上を推奨）
  mfa_configuration = "OFF"

  tags = { Project = var.project_name }
}

# ===== Hosted UI 用ドメイン =====
# OAuth のログイン画面・トークンエンドポイントを提供

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# ===== App Client: Web（Next.js / SPA） =====
# 公開クライアント（シークレットなし）。Authorization Code + PKCE

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.project_name}-web"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false # SPA はシークレットを安全に保持できないため公開クライアント

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = ["http://localhost:3000/callback"]
  logout_urls   = ["http://localhost:3000"]

  # リフレッシュトークンでアクセストークンを再発行する標準フローも許可
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
}

# ===== App Client: Mobile（React Native / Expo） =====

resource "aws_cognito_user_pool_client" "mobile" {
  name         = "${var.project_name}-mobile"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  # ネイティブアプリはカスタムスキームでコールバックを受ける
  callback_urls = ["myapp://callback"]
  logout_urls   = ["myapp://signout"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
}
