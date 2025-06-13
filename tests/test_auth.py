import pytest
from fastapi.testclient import TestClient
from jose import jwt

from app.core.config import settings


def test_health_check(client: TestClient):
    """
    Test health check endpoint
    """
    response = client.get("/auth/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data
    assert "timestamp" in data


def test_refresh_token_success(client: TestClient, valid_refresh_token: str):
    """
    Test successful token refresh
    """
    response = client.post(
        "/auth/refresh",
        json={"refresh_token": valid_refresh_token}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    
    # Verify the token is valid
    payload = jwt.decode(
        data["access_token"],
        settings.JWT_SECRET,
        algorithms=[settings.JWT_ALGORITHM]
    )
    assert payload["sub"] == "test-user"
    assert payload["type"] == "access"


def test_refresh_token_expired(client: TestClient, expired_refresh_token: str):
    """
    Test expired refresh token
    """
    response = client.post(
        "/auth/refresh",
        json={"refresh_token": expired_refresh_token}
    )
    assert response.status_code == 401
    assert "detail" in response.json()


def test_refresh_token_invalid(client: TestClient):
    """
    Test invalid refresh token
    """
    response = client.post(
        "/auth/refresh",
        json={"refresh_token": "invalid-token"}
    )
    assert response.status_code == 401
    assert "detail" in response.json()


def test_refresh_token_missing(client: TestClient):
    """
    Test missing refresh token
    """
    response = client.post("/auth/refresh", json={})
    assert response.status_code == 422  # Validation error
