import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    ELASTICSEARCH_URL = os.getenv("ELASTICSEARCH_URL", "")