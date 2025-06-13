#!/bin/bash

# Script para configurar el entorno en una instancia EC2 con Ubuntu
# Este script debe ejecutarse como root o con sudo

# Actualizar paquetes
echo "Actualizando paquetes del sistema..."
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y

# Instalar dependencias
echo "Instalando dependencias..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    htop \
    unzip \
    git

# Instalar Docker
echo "Instalando Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose
echo "Instalando Docker Compose..."
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
ln -sf $DOCKER_CONFIG/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Verificar Docker está funcionando
systemctl start docker
systemctl enable docker
docker --version

# Configurar usuario no root para Docker
echo "Configurando usuario para Docker..."
id -u ubuntu &>/dev/null || useradd -m ubuntu
usermod -aG docker ubuntu

# Crear directorio para la aplicación
echo "Configurando directorio de la aplicación..."
APP_DIR="/home/ubuntu/token-refresh-service"
mkdir -p $APP_DIR
chown -R ubuntu:ubuntu $APP_DIR

# Clonar el repositorio si no existe
if [ ! -d "$APP_DIR/.git" ]; then
    echo "Clonando repositorio del proyecto..."
    # Cambia la URL a tu repositorio real
    su - ubuntu -c "git clone https://github.com/tu-usuario/token-refresh-service.git $APP_DIR"
fi

# Configurar script de monitoreo
echo "Configurando script de monitoreo..."
cat > /usr/local/bin/check_service.sh << 'EOL'
#!/bin/bash
# Script para verificar la salud del servicio de refresh de tokens

echo "Verificando salud del servicio..."
HEALTH_URL="http://localhost:8001/auth/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ "$RESPONSE" = "200" ]; then
    echo "Service is healthy"
    exit 0
else
    echo "Service is down"
    exit 1
fi
EOL

chmod +x /usr/local/bin/check_service.sh

# Configurar script de reinicio
echo "Configurando script de reinicio..."
cat > /usr/local/bin/restart_service.sh << 'EOL'
#!/bin/bash
# Script para reiniciar el servicio de refresh de tokens

echo "Reiniciando servicio..."
cd /home/ubuntu/token-refresh-service
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
echo "Servicio reiniciado"
EOL

chmod +x /usr/local/bin/restart_service.sh

# Configuración cron para reinicio automático si falla el servicio
echo "Configurando monitoreo automático..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/check_service.sh || /usr/local/bin/restart_service.sh") | crontab -

# Configurar logrotate para los logs de Docker
echo "Configurando logrotate para Docker..."
cat > /etc/logrotate.d/docker-containers << 'EOL'
/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  size=10M
  missingok
  delaycompress
  copytruncate
}
EOL

# Configurar actualizaciones automáticas de seguridad
echo "Configurando actualizaciones automáticas de seguridad..."
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Limpiar
echo "Limpiando paquetes innecesarios..."
apt-get autoremove -y
apt-get clean

echo "=============================================="
echo "Configuración completada con éxito!"
echo "Por favor ejecuta estos comandos para continuar:"
echo "1. Copia el código a la instancia:"
echo "   scp -i tu-clave.pem -r token-refresh-service ubuntu@tu-ec2-ip:~"
echo "2. Conéctate a la instancia:"
echo "   ssh -i tu-clave.pem ubuntu@tu-ec2-ip"
echo "3. Despliega el servicio:"
echo "   cd ~/token-refresh-service && docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
echo "=============================================="
