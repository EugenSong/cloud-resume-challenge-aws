import json
import boto3
from decimal import Decimal

# Specify the profile to use (ONLY for Local testing)
# boto3.setup_default_session(profile_name="iamadmin-general")


def lambda_handler(event=None, context=None):
    # Initialize a DynamoDB client, specify the AWS region where your table is hosted
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

    # Specify your table name
    table = dynamodb.Table("VisitorCounts")

    # Update the item in DynamoDB table
    try:
        response = table.update_item(
            Key={"PageID": "ResumePage"},  # Primary key of the item to update
            UpdateExpression="ADD VisitCount :inc",  # Adds the specified value to the item's count
            ExpressionAttributeValues={
                ":inc": 1
            },  # Value to add (initializes if not present)
            ReturnValues="UPDATED_NEW",  # Returns the new value of the updated attribute
        )

        # Get the updated count from the response
        updated_count = response["Attributes"]["VisitCount"]

        # Convert Decimal to int
        updated_count = (
            int(updated_count) if isinstance(updated_count, Decimal) else updated_count
        )

        # Prepare the JSON response
        response_body = {
            "statusCode": 200,
            "updatedCount": updated_count,
            "message": "Visit count updated successfully",
        }

        # Return the JSON response
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",  # Allows any domain to access
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",  # Allowed request methods
                "Access-Control-Allow-Headers": "Content-Type",  # Allowed headers
            },
            "body": json.dumps(response_body),
        }

    except Exception as e:
        # Error handling: print the error message and return an error response
        print(f"Error updating DynamoDB table: {str(e)}")

        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",  # CORS header
            },
            "body": json.dumps({"message": "Error updating visit count"}),
        }


# Uncomment the following line for local testing
# lambda_handler()
