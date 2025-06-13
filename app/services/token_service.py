from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from fastapi import HTTPException, status
import httpx
from loguru import logger

from app.core.config import settings
from app.core.security import create_access_token, decode_token
from app.core.http_client import auth_service_client
from app.schemas.token import Token


class TokenService:
    """Token service"""
    
    async def refresh_token(self, refresh_token: str) -> Token:
        """
        Validate refresh token and create new access token
        """
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
        try:
            # Decode and validate refresh token
            payload = decode_token(refresh_token)
            
            # Check if it's a refresh token
            if payload.get("type") != "refresh":
                raise credentials_exception
            
            # Get user ID from token
            user_id: str = payload.get("sub")
            if user_id is None:
                raise credentials_exception
                
            # Check if token is expired
            exp = payload.get("exp")
            if exp is None or datetime.utcnow() > datetime.fromtimestamp(exp):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Refresh token expired",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            
            # Verificar que el usuario existe en el servicio de autenticación
            try:
                await self.validate_user_with_auth_service(user_id)
            except Exception as e:
                logger.error(f"Error validando usuario con servicio de autenticación: {str(e)}")
                # Si no podemos validar con el servicio de autenticación, confiamos en el token
                # pero registramos el error
                pass
                
            # Create new access token
            access_token = create_access_token(subject=user_id)
            return Token(access_token=access_token)
            
        except JWTError:
            raise credentials_exception
    
    async def validate_user_with_auth_service(self, user_id: str) -> Dict[str, Any]:
        """
        Validar que el usuario existe en el servicio de autenticación
        """
        try:
            # Llamar al endpoint de validación de usuario en el servicio de autenticación
            # Este endpoint debería existir o crearse en el servicio de autenticación
            response = await auth_service_client.get(
                f"/api/v1/users/{user_id}/validate",
                headers={"X-Service-Key": settings.JWT_SECRET[:32]}
            )
            return response
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error validating user: {str(e)}",
            )


token_service = TokenService()
