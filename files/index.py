import boto3
import json
import time
import botocore
          
def lambda_handler (event, context):
    # Setting the client for ECR (client), and for CloudWatch (cwclient)
    client = boto3.client('ecr')
    cwclient = boto3.client('logs')
    
    millis = int(round(time.time() * 1000))
    # Getting information from the event, to use it in the 'describe_image_scan_findings' API request
    accId = event['account']
    image = { "imageDigest": event['detail']["image-digest"], "imageTag": event['detail']["image-tags"][0]}
    repo = event['detail']['repository-name']
    # Initiate the DescribeImageScanFinding request, saving the response as a dictionary
    response = client.describe_image_scan_findings(
        registryId=accId,
        repositoryName=repo,
        imageId=image,
        maxResults=1000
    )
    # Try to create a Log Group for the repository with the repo's name passed in the event, if it already exists (from a previous scan, for example), creation will be aborted. Log group name format: /aws/ecr/image-scan-findings/repo-name
    
    RepoLogGroupName = '/aws/ecr/image-scan-findings/'+event['detail']['repository-name']
    try:
        cwclient.create_log_group(
            logGroupName=RepoLogGroupName
        )
    except cwclient.exceptions.ResourceAlreadyExistsException:
        print('Log Group already exists for the repo '+RepoLogGroupName+ ', creating aborted')
    # Create Log streams, one log stream for each severity, and one for total numbers (summary)
    SummaryLogStream = 'SUMMARY-'+event['detail']["image-tags"][0]+'-'+event['detail']["image-digest"].replace ('sha256:','')+'-'+event['time'].replace(':','-')
    cwclient.create_log_stream(logGroupName=RepoLogGroupName,logStreamName= SummaryLogStream)
    cwclient.put_log_events(logGroupName=RepoLogGroupName, logStreamName=SummaryLogStream,
                logEvents=[
                    {
                    'timestamp': millis,
                    'message': json.dumps(response['imageScanFindings']['findingSeverityCounts'])
                    }
                ])
    # StreamNameDictMapping used for mapping each severity (key) to StreamName (value)
    StreamNameDictMapping = {}
    # SequenceTokenDict maps each severity (key) to sequenceToken (value), used for put_log_events later
    SequenceTokenDict = {}
    # Log stream name format: SEVERITY-IMAGE_TAG-DIGEST-TIME_OF_SCAN, only dashes with no colons
    # Log stream names are uniquely named, as it uses the 'time' value from the scan complete ECR event.
    for i in response['imageScanFindings']['findingSeverityCounts']:
        StreamName = i+'-'+event['detail']["image-tags"][0]+'-'+event['detail']["image-digest"].replace ('sha256:','')+'-'+event['time'].replace(':','-')
        StreamNameDictMapping[i] = StreamName
        cwclient.create_log_stream(
            logGroupName=RepoLogGroupName,
            logStreamName= StreamName
        )
        SequenceTokenDict[i] = '0'
    # The following loop with 'put_log_events' will go through each finding, and based on severity, puts each finding in the corresponding log stream
    for i in response['imageScanFindings']['findings']:
        severity = i['severity']
        loggingResponse = cwclient.put_log_events(
            logGroupName=RepoLogGroupName,
            logStreamName=StreamNameDictMapping[severity],
            logEvents=[
                {
                'timestamp': millis,
                'message': json.dumps(i)
                }
            ],
            sequenceToken=SequenceTokenDict[severity]
        )
        SequenceTokenDict[severity] = loggingResponse['nextSequenceToken']
        print('Logged '+ i['name'] + ' in ' +StreamNameDictMapping[severity])
    print('Scan logging for '+ event['detail']["image-digest"]+':'+event['detail']["image-tags"][0]+ ' is complete.')
