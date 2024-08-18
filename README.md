
# GitHub Pull Request Logging with Terraform and AWS Lambda

This project sets up an AWS Lambda function that logs GitHub pull request details, including the repository name and changed files. It uses AWS API Gateway to handle incoming webhook requests from GitHub and Terraform for infrastructure management.

## Project Overview

-   **AWS Lambda**: Processes GitHub webhook events to log pull request details.
-   **AWS API Gateway**: Exposes an HTTP endpoint to receive GitHub webhook payloads.
-   **GitHub Webhook**: Triggers Lambda function on pull request events.
-   **Terraform**: Manages AWS and GitHub resources.

## Prerequisites

Before you begin, ensure you have the following:

-   **Terraform** installed on your machine.
-   **AWS CLI** configured with your AWS credentials.
-   **GitHub Token** with appropriate permissions to manage webhooks.

## Setup

### 1. Export Environment Variables

Ensure you export the following environment variables for AWS and GitHub credentials:

 ```# Set AWS credentials
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"

# Set GitHub token
export GITHUB_TOKEN="your_github_token"
```

### 2. Configure Terraform

Update your Terraform configuration to include necessary variables and resources.

**Note**: You can use environment variables for sensitive values, avoiding the use of a `terraform.tfvars` file.

### 3. Initialize and Apply Terraform Configuration

Run the following commands to initialize and apply the Terraform configuration:

```
terraform init
terraform apply
```

### 4. Verify Setup

After applying the Terraform configuration, ensure:

-   The AWS Lambda function is deployed and configured correctly.
-   The API Gateway endpoint is created and associated with the Lambda function.
-   The GitHub webhook is set up and pointing to the API Gateway URL.

## Lambda Function

The Lambda function processes incoming GitHub webhook events to log details of pull requests:

-   **Repository Name**
-   **Changed Files and their Statuses**

### Lambda Code

The Lambda function is defined in `lambda_latest.py` and is packaged into a deployment zip file. Ensure that your Lambda code correctly handles GitHub payloads.

## API Gateway

API Gateway is set up to handle HTTP POST requests and trigger the Lambda function. The endpoint URL is configured in the GitHub webhook settings.

## GitHub Webhook Configuration

The GitHub webhook is configured to send pull request events to the API Gateway URL:

-   **URL**: `${aws_api_gateway_deployment.api_deployment.invoke_url}/webhook`
-   **Content Type**: `json`

## Cleaning Up

To delete all resources created by Terraform, run:
```
terraform destroy --auto-approve
```

## Troubleshooting

-   **Invalid Payload Errors**: Ensure the Lambda function correctly parses the incoming payload.
-   **Permissions Issues**: Verify IAM roles and policies associated with the Lambda function and API Gateway.
-   **GitHub Token Errors**: Check that the GitHub token has the required permissions and is correctly set in environment variables.

