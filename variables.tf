variable "github_token" {
  description = "GitHub personal access token with repo scope"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-1"
}

