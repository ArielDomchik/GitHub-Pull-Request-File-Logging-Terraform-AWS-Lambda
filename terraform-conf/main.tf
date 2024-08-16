terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "arieldomchik"

    workspaces {
      name = "checkpoint"
    }
  }
}

data "aws_iam_role" "existing_lambda_role" {
  name = "lambda_role"
}

provider "aws" {
  region     = "us-west-2"
  access_key = "AKIARHNCG4PTBH2FA6WR"
  secret_key = "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"

}

provider "github" {
  token = var.github_token
}


# Create IAM Role for Lambda


# Create a temporary file with the Lambda code
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "checkpoint-assignment-lambda-role"
  acl    = "private"
}


# Lambda Function
resource "aws_lambda_function" "example" {
  function_name = "example_lambda_function"
  role          = data.aws_iam_role.existing_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  s3_bucket        = aws_s3_bucket.lambda_bucket.bucket
  s3_key           = "lambda_function.zip"
  runtime       = "python3.8"
}



# API Gateway setup
resource "aws_apigatewayv2_api" "example" {
  name          = "endpoint"
  protocol_type = "HTTP"
  description   = "API Gateway for GitHub Webhook"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id                 = aws_apigatewayv2_api.example.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.example.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "POST /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.example.id}"
}

resource "aws_apigatewayv2_stage" "example" {
  api_id      = aws_apigatewayv2_api.example.id
  name        = "prod"
  auto_deploy = true
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.example.execution_arn}/*/*"
}

# GitHub Repository
resource "github_repository" "example" {
  name        = "Checkpoint"
  description = "Log pull request files and repository name"
  visibility  = "private"
}

# GitHub Webhook for Pull Request events
resource "github_repository_webhook" "example" {
  repository = github_repository.example.name
  configuration {
    url          = "${aws_apigatewayv2_api.example.api_endpoint}/webhook" # API Gateway URL
    content_type = "json"
  }
  events = ["pull_request"]
  active = true
}
