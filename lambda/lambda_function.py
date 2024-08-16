import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # GitHub webhook event
    body = json.loads(event['body'])
    
    # Extract repository name
    repository_name = body['repository']['full_name']
    logger.info(f"Repository: {repository_name}")
    
    # Extract pull request details
    if 'pull_request' in body:
        pr = body['pull_request']
        if pr['merged']:
            logger.info(f"Pull Request #{pr['number']} merged")
            # Log the files changed in the pull request
            for file in pr['files']:
                logger.info(f"File {file['status']}: {file['filename']}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Webhook received')
    }

