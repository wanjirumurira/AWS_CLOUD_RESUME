import boto3
from datetime import datetime
import pytz 
import json


def lambda_handler(event:any, context:any):
    
    #create a dynamodb table
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("visitor_counter")
 
     # Query the DynamoDB table to get the current maximum user ID
    response = table.scan(Select="COUNT")
    current_count = response["Count"]

    # Increment the user count to get a new unique user ID
    visit_count = current_count + 1
    eat_timezone = pytz.timezone('Africa/Nairobi')
    time_visited = datetime.now(eat_timezone).strftime("%Y-%m-%d %H:%M")

    item = {
        "user_id": "user"+ str(visit_count),
        "count": visit_count,
        "time": time_visited
    }
    
    #Put the new visit count into the table
    table.put_item(Item=item)
    message = f"Hello!This page has been visited {visit_count} times." 
    response = {"Message" : message,
            "count": visit_count}
    return response

#Compress-Archive -Path .\lambda_function.py, .\venv\lib\site-packages\* -DestinationPath my_lambda_function.zip