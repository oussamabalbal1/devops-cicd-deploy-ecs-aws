resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-db-password-secret"
  tags = {
    Name = "${var.project_name}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_value" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}



resource "aws_secretsmanager_secret" "db_host" {
  name = "${var.project_name}-db-host-secret"
  tags = {
    Name = "${var.project_name}-db-host"
  }
}

resource "aws_secretsmanager_secret_version" "db_host_value" {
  secret_id     = aws_secretsmanager_secret.db_host.id
  secret_string = aws_db_instance.main.address
}