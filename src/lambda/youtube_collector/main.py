import boto3
import requests
from datetime import datetime
import os
import json

def lambda_handler(event, context):
    # Get YouTube API key from environment
    api_key = os.environ['YOUTUBE_API_KEY']
    
    # API endpoint for trending videos
    url = 'https://www.googleapis.com/youtube/v3/videos'
    
    # Parameters for API request
    params = {
        'part': 'snippet,statistics',
        'chart': 'mostPopular',
        'regionCode': 'US',
        'maxResults': 50,
        'key': api_key
    }
    try:
    # Make API request
        response = requests.get(url, params=params)
        videos = response.json()
        
        # Generate S3 key with partition
        date_path = datetime.now().strftime('%Y/%m/%d')
        s3_key = f'raw/videos/{date_path}/data.json'
        
        # Save to S3
        s3 = boto3.client('s3')
        s3.put_object(
            Bucket=os.environ['RAW_BUCKET'],
            Key=s3_key,
            Body=json.dumps(videos),
        )
        
        return {
            'statusCode': 200,
            'body': f'Data collected and saved to {s3_key}'
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")  # CloudWatch logs
        return {
            'statusCode': 500,
            'body': f'Error processing request: {str(e)}'
        }