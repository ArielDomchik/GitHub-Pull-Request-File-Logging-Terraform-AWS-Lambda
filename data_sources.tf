data "aws_region" "current" {}

data "aws_iam_role" "existing_lambda_role" {
  name = "lambda_role"
}

