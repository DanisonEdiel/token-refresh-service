#!/bin/bash

# Script para configurar el entorno AWS en EC2
# Este script debe ejecutarse en la instancia EC2 después del despliegue

# Crear directorio para scripts
mkdir -p /home/ec2-user/scripts

# Instalar herramientas útiles
echo "Instalando herramientas útiles..."
sudo yum update -y
sudo yum install -y jq curl wget htop

# Configurar el cliente de AWS
echo "Configurando AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "Instalando AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Configurar región por defecto
echo "Configurando región por defecto..."
mkdir -p ~/.aws
cat > ~/.aws/config << EOL
[default]
region = ${AWS_REGION:-us-east-1}
output = json
EOL

# Verificar la identidad de la instancia
echo "Verificando identidad de la instancia..."
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
echo "Instancia: $INSTANCE_ID en región: $REGION"

# Crear script para verificar la salud del servicio
cat > /home/ec2-user/scripts/check_health.sh << EOL
#!/bin/bash
# Script para verificar la salud del servicio de refresh de tokens

echo "Verificando salud del servicio..."
HEALTH_URL="http://localhost:8001/auth/health"
RESPONSE=\$(curl -s \$HEALTH_URL)

if [[ \$? -eq 0 && \$RESPONSE == *"ok"* ]]; then
    echo "Servicio saludable: \$RESPONSE"
    exit 0
else
    echo "Servicio no saludable: \$RESPONSE"
    exit 1
fi
EOL

# Hacer ejecutable el script de salud
chmod +x /home/ec2-user/scripts/check_health.sh

# Crear script para reiniciar el servicio
cat > /home/ec2-user/scripts/restart_service.sh << EOL
#!/bin/bash
# Script para reiniciar el servicio de refresh de tokens

echo "Reiniciando servicio..."
cd ~/token-refresh-service
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
echo "Servicio reiniciado"
EOL

# Hacer ejecutable el script de reinicio
chmod +x /home/ec2-user/scripts/restart_service.sh

echo "Configuración completada"
