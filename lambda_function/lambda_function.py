import boto3
from datetime import datetime
import pytz 
import json


def lambda_handler(event:any, context:any):
    
    #create a dynamodb table
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("visitor-count-table")
 
     # Query the DynamoDB table to get the current maximum user ID
    response = table.scan(Select="COUNT")
    current_count = response["Count"]

    # Increment the user count to get a new unique user ID
    visit_count = current_count + 1
    eat_timezone = pytz.timezone('Africa/Nairobi')
    time_visited = datetime.now(eat_timezone).strftime("%Y-%m-%d %H:%M")

    item = {
        "user": "user"+ str(visit_count),
        "count": visit_count,
        "time": time_visited
    }
    
    #Put the new visit count into the table
    table.put_item(Item=item)
<<<<<<< HEAD
    #message = f"Hello!This page has been visited {visit_count} times." 
    results = {"count": visit_count}
    return json.dumps(results)
=======
    message = f"Hello!This page has been visited {visit_count} times." 
    results = {"Message" : message,
            "count": visit_count}
    return results
>>>>>>> 56a9797cb2110ece6989ea08878b3293c436a47d

#Compress-Archive -Path .\lambda_function.py, .\venv\lib\site-packages\* -DestinationPath my_lambda_function.zip
