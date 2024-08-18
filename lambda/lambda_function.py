import os
import json
import requests

def lambda_handler(event, context):
    # Extract GitHub token from environment variables
    github_token = os.environ.get('GITHUB_TOKEN')
    if not github_token:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "GitHub token not found in environment variables"})
        }

    # Ensure the event body is parsed if coming in as a string
    if isinstance(event.get('body'), str):
        try:
            event = json.loads(event['body'])
        except json.JSONDecodeError:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Invalid JSON in request body"})
            }

    # Extract repository name and pull request number from the event
    repository_name = event.get("repository", {}).get("full_name") 
    pull_request_number = event.get("number")
    
    if not repository_name or not pull_request_number:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Repository name or Pull Request number is missing"})
        }

    # Construct the URL to fetch the pull request details
    pr_url = f"https://api.github.com/repos/{repository_name}/pulls/{pull_request_number}/files"
    headers = {
        "Authorization": f"token {github_token}"
    }

    try:
        # Fetch pull request files from GitHub API
        response = requests.get(pr_url, headers=headers)
        response.raise_for_status()
        pr_files = response.json()
    except requests.RequestException as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

    # Create output text with only necessary details
    output_text = f"Repository Name: {repository_name}\n"
    output_text += "Modified Files:\n"

    if not pr_files:
        output_text += "No files found.\n"
    else:
        for file in pr_files:
            filename = file.get("filename", "Unknown File")
            status = file.get("status", "Unknown Status")
            output_text += f"- {filename} (Status: {status})\n"

    # Print only the relevant output to CloudWatch Logs
    print(output_text)

    # Return success message with filtered details
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Success", "details": output_text})
    }

