import os
import requests
from dotenv import load_dotenv
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth
import boto3

load_dotenv()

credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, "us-east-1", "es", session_token=credentials.token)
opensearch_endpoint = os.getenv("ELASTICSEARCH_URL")

client = OpenSearch(
    hosts=[{'host': opensearch_endpoint, 'port': 443}],
    http_auth=awsauth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

r = requests.get(opensearch_endpoint, auth=awsauth)
print(r.status_code)
print(r.text)
