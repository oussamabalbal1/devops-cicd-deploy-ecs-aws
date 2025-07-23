# -----------------------------------------------------------------------------
# GENERAL VARIABLES
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "nestjs-app"
}

# -----------------------------------------------------------------------------
# NETWORKING VARIABLES
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  description = "The CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# -----------------------------------------------------------------------------
# DOMAIN & CERTIFICATE VARIABLES
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "The domain name for the application (e.g., myapp.example.com)."
  type        = string
}

variable "route53_zone_id" {
  description = "The Route 53 Hosted Zone ID for the domain."
  type        = string
}

# -----------------------------------------------------------------------------
# DATABASE VARIABLES
# -----------------------------------------------------------------------------

variable "db_username" {
  description = "The username for the RDS database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the RDS database."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "The database name for the RDS database."
  type        = string
  default     = "nestdb"
}

# -----------------------------------------------------------------------------
# GITHUB & CODEPIPELINE VARIABLES
# -----------------------------------------------------------------------------

variable "github_owner" {
  description = "The owner of the GitHub repository."
  type        = string
}

variable "github_repo" {
  description = "The name of the GitHub repository."
  type        = string
}

variable "github_branch" {
  description = "The branch to trigger the pipeline from."
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "The GitHub personal access token for CodePipeline source."
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# COGNITO VARIABLES
# -----------------------------------------------------------------------------

variable "cognito_domain_prefix" {
  description = "A unique prefix for the Cognito User Pool domain."
  type        = string
}
