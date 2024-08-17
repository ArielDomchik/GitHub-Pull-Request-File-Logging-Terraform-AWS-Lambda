import json
import os
import requests

def lambda_handler(event, context):
    # Extract GitHub token from environment variables
    github_token = os.environ.get('GITHUB_TOKEN')
    if not github_token:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "GitHub token not found in environment variables"})
        }

    # Extract repository name and pull request number from the event
    repository_name = event.get("repository", {}).get("full_name", "Unknown Repository")
    pull_request_number = event.get("pull_request", {}).get("number", "Unknown PR")
    
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

    # Create output text
    output_text = f"Repository Name: {repository_name}\n"
    output_text += f"Pull Request Number: {pull_request_number}\n"
    output_text += "Modified Files:\n"

    if not pr_files:
        output_text += "No files found.\n"
    else:
        for file in pr_files:
            filename = file.get("filename", "Unknown File")
            status = file.get("status", "Unknown Status")
            output_text += f"- {filename} (Status: {status})\n"

    # Print output to CloudWatch Logs
    print(output_text)

    # Return the response as JSON (optional)
    return {
        "statusCode": 200,
        "body": json.dumps({
            "repository_name": repository_name,
            "pull_request_number": pull_request_number,
            "modified_files": [{"filename": file.get("filename", "Unknown File"), "status": file.get("status", "Unknown Status")} for file in pr_files]
        })
    }

