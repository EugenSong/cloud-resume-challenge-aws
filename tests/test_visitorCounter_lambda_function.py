import json
import boto3
from decimal import Decimal
from moto import mock_aws
import pytest

# Add the parent directory to sys.path to import lambda_function.py
from backend.visitor_counter import lambda_handler


@pytest.fixture(scope="function")
def dynamodb():
    """
    Create a mock DynamoDB instance with the VisitorCounts table.
    Yields the DynamoDB resource instance.
    """
    with mock_aws():
        dynamodb_resource = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamodb_resource.create_table(
            TableName="VisitorCounts",
            KeySchema=[{"AttributeName": "PageID", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "PageID", "AttributeType": "S"}],
            ProvisionedThroughput={"ReadCapacityUnits": 1, "WriteCapacityUnits": 1},
        )
        table.put_item(Item={"PageID": "ResumePage", "VisitCount": Decimal("0")})
        yield dynamodb_resource

def test_successful_update(dynamodb):
    """Test a successful DynamoDB update"""
    table = dynamodb.Table("VisitorCounts")

    # Create a sample event object
    event = {
        "httpMethod": "GET",
        "queryStringParameters": None
    }

    # Call the lambda_handler function with the event object
    response = lambda_handler(event, None)

    # Assert the response
    assert response["statusCode"] == 200
    assert "application/json" in response["headers"]["Content-Type"]

    # Parse the response body
    response_body = json.loads(response["body"])
    assert response_body["updatedCount"] == 1
    assert response_body["message"] == "Visit count updated successfully"

    # Assert the updated count in the DynamoDB table
    updated_count = table.get_item(Key={"PageID": "ResumePage"})["Item"]["VisitCount"]
    assert updated_count == 1