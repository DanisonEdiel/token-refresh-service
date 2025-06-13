from typing import Generator
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError

from app.core.config import settings
from app.core.security import decode_token
from app.schemas.token import TokenPayload

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"/auth/login")


def get_token_payload(token: str = Depends(oauth2_scheme)) -> TokenPayload:
    """
    Decode and validate JWT token
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = decode_token(token)
        token_data = TokenPayload(**payload)
        
        # Check if token is access token
        if token_data.type != "access":
            raise credentials_exception
            
        return token_data
    except (JWTError, ValueError):
        raise credentials_exception
