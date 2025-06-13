import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_refresh_token


@pytest.fixture
def client():
    """
    Test client fixture
    """
    with TestClient(app) as client:
        yield client


@pytest.fixture
def valid_refresh_token():
    """
    Valid refresh token fixture
    """
    return create_refresh_token(subject="test-user")


@pytest.fixture
def expired_refresh_token():
    """
    Expired refresh token fixture
    """
    from datetime import timedelta
    return create_refresh_token(subject="test-user", expires_delta=timedelta(days=-1))
