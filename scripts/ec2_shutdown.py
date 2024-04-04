import boto3
import os

def check_instance_status(instance_id, region):
    ec2_client = boto3.client('ec2', region_name=region)
    try:
        response = ec2_client.describe_instance_status(InstanceIds=[instance_id])
        print("Instance Response: ", response)
        if len(response['InstanceStatuses']) > 0:
            instance_status = response['InstanceStatuses'][0]['InstanceState']['Name']
            return instance_status
        else:
            return None
    except Exception as e:
        print("Error:", e)
        return None

def stop_instance(instance_id, region):
    ec2_client = boto3.client('ec2', region_name=region)
    try:
        ec2_client.stop_instances(InstanceIds=[instance_id])
        print("Instance stopped successfully.")
    except Exception as e:
        print("Error stopping instance:", e)

def main(event, context):
    
    region = os.environ['REGION']
    instance_id = os.environ['EC2_ID']

    instance_status = check_instance_status(instance_id, region)
    if instance_status == 'running':
        print("Instance is running. Stopping the instance...")
        stop_instance(instance_id, region)
    elif instance_status == 'stopped':
        print("Instance is already stopped.")
    else:
        print("Instance status unknown or instance does not exist.")