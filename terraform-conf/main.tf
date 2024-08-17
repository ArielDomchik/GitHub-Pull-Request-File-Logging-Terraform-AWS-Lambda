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


resource "aws_s3_bucket_object" "lambda_package" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  key    = "my_deployment.zip"
  source = "${path.module}/lambda/my_deployment.zip" 
}


# Lambda Function
resource "aws_lambda_function" "example" {
  function_name = "lambda_function"
  role          = data.aws_iam_role.existing_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  s3_bucket        = aws_s3_bucket.lambda_bucket.bucket
  s3_key           = aws_s3_bucket_object.lambda_package.key
  runtime       = "python3.10"

  environment {
    variables = {
      GITHUB_TOKEN = var.github_token
    }
  }

}



# API Gateway setup

resource "aws_api_gateway_rest_api" "github_webhook_api" {
  name        = "github-webhook-api"
  description = "API for GitHub webhook"
}

resource "aws_api_gateway_resource" "webhook_resource" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  parent_id   = aws_api_gateway_rest_api.github_webhook_api.root_resource_id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id   = aws_api_gateway_resource.webhook_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  resource_id = aws_api_gateway_resource.webhook_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/${aws_lambda_function.example.arn}/invocations"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.github_webhook_api.id
  stage_name  = "prod"
}


resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.api_deployment.execution_arn}/*/*"
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
    url          = "${aws_api_gateway_deployment.api_deployment.invoke_url}/webhook" # API Gateway URL
    content_type = "json"
  }
  events = ["pull_request"]
  active = true
}
