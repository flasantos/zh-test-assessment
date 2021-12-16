import json.decoder
import requests
import pytest
from app.resources.currency import Currency


class MockInvalidCurrencyResponse:
    def __init__(self):
        self.status_code = 400

    @staticmethod
    def json():
        return {"errors": [{"id": "invalid_request", "message": "Currency is invalid"}]}


class MockInvalidJsonResponse:
    @staticmethod
    def json():
        raise json.decoder.JSONDecodeError(msg='invalid json', doc='', pos=0)


@pytest.fixture
def mock_response_get_currency_with_invalid_json(monkeypatch):
    def mock_get(*args, **kwargs):
        return MockInvalidJsonResponse()

    monkeypatch.setattr(requests, "get", mock_get)


@pytest.fixture
def mock_response_get_currency_with_invalid_currency(monkeypatch):
    def mock_get(*args, **kwargs):
        return MockInvalidCurrencyResponse()

    monkeypatch.setattr(requests, "get", mock_get)


def test_get_currency_response_with_invalid_json(mock_response_get_currency_with_invalid_json):
    result = Currency().get(currency='BRL')
    assert result[0]['error'] == 'invalid json response'


def test_get_currency_response_with_invalid_currency(mock_response_get_currency_with_invalid_currency):
    result = Currency().get(currency='BLR')
    print(result)
    assert result[0]['errors'][0]['message'] == 'Currency is invalid'
