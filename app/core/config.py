from typing import Any, Optional

from pydantic import BaseSettings, Field

class Settings(BaseSettings):
    """Application settings"""
    
    # API settings
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Token Refresh Service"
    VERSION: str = "1.0.0"
    
    # Security
    JWT_SECRET: str = Field(..., env="JWT_SECRET")
    JWT_ALGORITHM: str = Field("HS256", env="JWT_ALGORITHM")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(30, env="JWT_ACCESS_TOKEN_EXPIRE_MINUTES")
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = Field(7, env="JWT_REFRESH_TOKEN_EXPIRE_DAYS")
    
    # CORS
    CORS_ORIGINS: list[str] = Field(["http://localhost:3000", "http://localhost:8080"], env="CORS_ORIGINS")
    
    # Rate limitin
    RATE_LIMIT_PER_MINUTE: int = Field(60, env="RATE_LIMIT_PER_MINUTE")
    
    # Logging
    LOG_LEVEL: str = Field("INFO", env="LOG_LEVEL")
    
    # Service communication
    AUTH_SERVICE_URL: str = Field("http://auth-service:8000", env="AUTH_SERVICE_URL")
    
    # AWS Configuration
    AWS_REGION: Optional[str] = Field(None, env="AWS_REGION")
    AWS_ACCESS_KEY_ID: Optional[str] = Field(None, env="AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY: Optional[str] = Field(None, env="AWS_SECRET_ACCESS_KEY")
    
    # Network configuration
    NETWORK_NAME: str = Field("auth-network", env="NETWORK_NAME")
    
    def get_cors_origins(self) -> list[str]:
        """Parse CORS_ORIGINS from string to list if needed"""
        if isinstance(self.CORS_ORIGINS, str):
            return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]
        return self.CORS_ORIGINS
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
