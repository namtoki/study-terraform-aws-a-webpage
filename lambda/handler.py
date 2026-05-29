import json
from datetime import datetime, timezone, timedelta


def lambda_handler(event, context):
    jst = timezone(timedelta(hours=9))
    now = datetime.now(jst)

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "timestamp": now.isoformat(),
            "source": "Lambda (dynamic)",
        }, ensure_ascii=False),
    }
