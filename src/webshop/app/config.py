""" resources needed by the app """

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Defines all necessary configuration parameters for the application"""

    ELASTICSEARCH_URL = os.getenv("ELASTICSEARCH_URL")
    KINESIS_STREAM_NAME = os.getenv("KINESIS_STREAM_NAME")
    LOGFIRE_TOKEN = os.getenv("LOGFIRE_TOKEN")
    LOGFIRE_URL = os.getenv("LOGFIRE_URL")
