import json
import boto3
from decimal import Decimal
from moto import mock_dynamodb2
import pytest
import sys
import os

# Add the parent directory to sys.path to import lambda_function.py
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from visitor_counter import lambda_handler

@pytest.fixture(scope="function")
def dynamodb():
    """
    Create a mock DynamoDB instance with the VisitorCounts table.
    Yields the DynamoDB resource instance.
    """
    with mock_dynamodb2():
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
    response = lambda_handler()
    response_body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert "application/json" in response["headers"]["Content-Type"]
    assert response_body["updatedCount"] == 1
    assert response_body["message"] == "Visit count updated successfully"
    updated_count = table.get_item(Key={"PageID": "ResumePage"})["Item"]["VisitCount"]
    assert updated_count == 1