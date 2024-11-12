from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

def transform_youtube_data():
    # Initialize Glue context
    glueContext = GlueContext(SparkContext.getOrCreate())
    
    # Read raw data
    dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
        database="youtube_db",
        table_name="raw_videos"
    )
    
    # Apply transformations
    transformed = dynamic_frame.apply_mapping([
        ("id", "string", "video_id", "string"),
        ("snippet.title", "string", "title", "string"),
        ("statistics.viewCount", "long", "views", "long"),
        ("statistics.likeCount", "long", "likes", "long")
    ])
    
    # Write transformed data
    glueContext.write_dynamic_frame.from_options(
        frame=transformed,
        connection_type="s3",
        connection_options={
            "path": "s3://processed-bucket/videos/",
            "partitionKeys": ["year", "month", "day"]
        },
        format="parquet"
    )