CREATE EXTERNAL TABLE youtube_videos (
    video_id STRING,
    title STRING,
    views BIGINT,
    likes BIGINT,
    published_date TIMESTAMP
)
PARTITIONED BY (year INT, month INT, day INT)
STORED AS PARQUET
LOCATION 's3://processed-bucket/videos/';