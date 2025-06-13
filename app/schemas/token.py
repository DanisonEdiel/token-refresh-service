from typing import Optional

from pydantic import BaseModel, Field


class Token(BaseModel):
    """Token schema"""
    access_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    """Token payload schema"""
    sub: str | None = None
    exp: int | None = None
    type: str | None = None


class RefreshTokenRequest(BaseModel):
    """Refresh token request schema"""
    refresh_token: str = Field(..., description="JWT refresh token")


class HealthResponse(BaseModel):
    """Health check response schema"""
    status: str
    version: str
    timestamp: str
