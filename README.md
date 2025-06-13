# Token Refresh Service

Microservicio para la renovación de tokens JWT de autenticación.

## Funcionalidades

- `POST /auth/refresh`: Validación de token de refresh y emisión de nuevo JWT de acceso.
- `GET /auth/health`: Comprobación de salud del servicio.

## Tecnologías

- Python 3.11+
- FastAPI + Pydantic
- JWT con HMAC256
- Rate limiting con slowapi
- Logging con loguru
- Métricas con Prometheus

## Estructura del Proyecto

```
token-refresh-service/
├── app/
│   ├── api/
│   │   ├── routes/
│   │   │   └── auth.py
│   │   └── deps.py
│   ├── core/
│   │   ├── config.py
│   │   ├── security.py
│   │   └── logging.py
│   ├── schemas/
│   │   └── token.py
│   ├── services/
│   │   └── token_service.py
│   └── main.py
├── tests/
│   ├── conftest.py
│   └── test_auth.py
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml
└── requirements.txt
```

## Instalación y Ejecución

### Usando Docker

```bash
# Clonar el repositorio
git clone https://github.com/yourusername/token-refresh-service.git
cd token-refresh-service

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus configuraciones

# Iniciar con Docker Compose
docker compose up -d
```

### Desarrollo Local

```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar en modo desarrollo
uvicorn app.main:app --reload
```

## Configuración

Variables de entorno disponibles en `.env`:

- `JWT_SECRET`: Clave secreta para firmar tokens JWT
- `JWT_ALGORITHM`: Algoritmo de firma (default: HS256)
- `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`: Tiempo de expiración del token de acceso
- `JWT_REFRESH_TOKEN_EXPIRE_DAYS`: Tiempo de expiración del token de refresh
- `CORS_ORIGINS`: Orígenes permitidos para CORS
- `RATE_LIMIT_PER_MINUTE`: Límite de peticiones por minuto
- `LOG_LEVEL`: Nivel de logging

## API Endpoints

### POST /auth/refresh

**Request:**
```json
{
  "refresh_token": "string"
}
```

**Response:**
```json
{
  "access_token": "string",
  "token_type": "bearer"
}
```

### GET /auth/health

**Response:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-06-13T20:02:15.123456"
}
```

## Seguridad

- Tokens JWT firmados con HMAC256
- Validación de tokens de refresh
- Rate limiting para prevenir ataques de fuerza bruta
- CORS configurado para restringir orígenes

## Pruebas

```bash
# Ejecutar pruebas
pytest

# Ejecutar con cobertura
pytest --cov=app
```

## Licencia

MIT
