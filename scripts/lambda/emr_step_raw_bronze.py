import boto3
import datetime
import os

emr = boto3.client('emr')

CLUSTER_ID = os.getenv("CLUSTER_ID")
SCRIPT_PATH = f"s3://{os.getenv("PATH_TO_SCRIPT")}"

def lambda_handler(event, context):
    today = datetime.datetime.utcnow().strftime('%Y-%m-%d')
    
    step = {
        'Name': f'RawToBronzeIngest-{today}',
        'ActionOnFailure': 'CONTINUE',
        'HadoopJarStep': {
            'Jar': 'command-runner.jar',
            'Args': [
                'spark-submit',
                '--deploy-mode', 'cluster',
                SCRIPT_PATH,
                '--today', today
            ]
        }
    }

    response = emr.add_job_flow_steps(
        JobFlowId=CLUSTER_ID,
        Steps=[step]
    )

    return {
        'statusCode': 200,
        'body': f"Added step ID(s): {response['StepIds']}"
    }
