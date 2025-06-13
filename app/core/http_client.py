from typing import Any, Optional

import httpx
from loguru import logger

from app.core.config import settings


class ServiceClient:
    """
    Cliente HTTP para comunicación entre servicios
    """
    
    def __init__(self, base_url: str, timeout: float = 10.0):
        self.base_url = base_url
        self.timeout = timeout
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=self.timeout
        )
    
    async def get(self, url: str, params: Optional[dict[str, Any]] = None, headers: Optional[dict[str, str]] = None) -> dict[str, Any]:
        """
        Realizar una solicitud GET
        """
        try:
            response = await self.client.get(url, params=params, headers=headers)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Error en solicitud GET a {url}: {str(e)}")
            raise
    
    async def post(self, url: str, json: Optional[dict[str, Any]] = None, data: Any = None, headers: Optional[dict[str, str]] = None) -> dict[str, Any]:
        """
        Realizar una solicitud POST
        """
        try:
            response = await self.client.post(url, json=json, data=data, headers=headers)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Error en solicitud POST a {url}: {str(e)}")
            raise
    
    async def close(self):
        """
        Cerrar cliente HTTP
        """
        await self.client.aclose()


# Cliente para el servicio de autenticación
auth_service_client = ServiceClient(base_url=settings.AUTH_SERVICE_URL)
