# -----------------------------------------------------------------------------
# COGNITO USER POOL
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  tags = {
    Name = "${var.project_name}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name = "${var.project_name}-user-pool-client"

  user_pool_id                           = aws_cognito_user_pool.main.id
  generate_secret                        = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                    = ["code", "implicit"]
  allowed_oauth_scopes                   = ["openid", "email", "profile"]
  supported_identity_providers           = ["COGNITO"]

  callback_urls = ["https://${trimspace(var.domain_name)}/oauth2/idpresponse"]
  logout_urls   = ["https://${trimspace(var.domain_name)}"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}
