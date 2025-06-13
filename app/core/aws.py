from typing import Any

import boto3
from loguru import logger

from app.core.config import settings


class AWSClient:
    """
    Cliente para servicios de AWS
    """
    
    def __init__(self):
        self.region = settings.AWS_REGION
        self.access_key = settings.AWS_ACCESS_KEY_ID
        self.secret_key = settings.AWS_SECRET_ACCESS_KEY
        
        # Verificar si tenemos credenciales configuradas
        self.is_configured = all([self.region, self.access_key, self.secret_key])
        
        if not self.is_configured:
            logger.warning("AWS credentials not configured. Using instance profile or environment variables.")
    
    def get_client(self, service_name: str):
        """
        Obtener cliente de AWS para un servicio específico
        """
        try:
            if self.is_configured:
                return boto3.client(
                    service_name,
                    region_name=self.region,
                    aws_access_key_id=self.access_key,
                    aws_secret_access_key=self.secret_key
                )
            else:
                # Usar credenciales del perfil de instancia o variables de entorno
                return boto3.client(service_name, region_name=self.region)
        except Exception as e:
            logger.error(f"Error creating AWS client for {service_name}: {str(e)}")
            raise
    
    def get_resource(self, service_name: str):
        """
        Obtener recurso de AWS para un servicio específico
        """
        try:
            if self.is_configured:
                return boto3.resource(
                    service_name,
                    region_name=self.region,
                    aws_access_key_id=self.access_key,
                    aws_secret_access_key=self.secret_key
                )
            else:
                # Usar credenciales del perfil de instancia o variables de entorno
                return boto3.resource(service_name, region_name=self.region)
        except Exception as e:
            logger.error(f"Error creating AWS resource for {service_name}: {str(e)}")
            raise


# Cliente global de AWS
aws_client = AWSClient()
