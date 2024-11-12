SELECT 
    title,
    views,
    likes,
    published_date
FROM 
    youtube_videos
WHERE 
    year = 2024
    AND month = 1
ORDER BY 
    views DESC
LIMIT 10;