import boto3
import base64
import gzip
import ast 
import os
import json
import datetime

ses = boto3.client('ses')

def notify(from_address, to_address, subject, message):
    ses.send_email(
        Source = from_address, 
        Destination={'ToAddresses': [to_address],'CcAddresses': []}, 
        Message={ 'Subject': {'Data': subject },'Body': {'Text': {'Data': message }}}
    )

def handler(event, context):
    body = json.dumps(event)
    subject = "AWS Notification"
    print(event)
    print(subject)
    print(body)
    notify(os.environ['EMAIL_FROM'], os.environ['EMAIL_TO'], subject, body)
    return body