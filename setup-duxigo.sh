#!/bin/bash

# Автоматический скрипт настройки для test.duxigo.org
# Использование: ./setup-duxigo.sh

set -e

DOMAIN="test.duxigo.org"
CALL_DOMAIN="call.test.duxigo.org"
SYNAPSE_DOMAIN="synapse.test.duxigo.org"

echo "=========================================="
echo "Настройка Element для $DOMAIN"
echo "=========================================="

# Проверка Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен. Устанавливаем..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Проверка Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose не установлен. Устанавливаем..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Создание .env файла
if [ ! -f .env ]; then
    echo "📝 Создание .env файла..."
    cat > .env << EOF
# Конфигурация для test.duxigo.org
SYNAPSE_BASE_URL=https://${SYNAPSE_DOMAIN}
SYNAPSE_SERVER_NAME=${DOMAIN}
SYNAPSE_HOST=${SYNAPSE_DOMAIN}

ELEMENT_WEB_DOMAIN=${DOMAIN}
ELEMENT_WEB_URL=https://${DOMAIN}

ELEMENT_CALL_BASE_URL=https://${CALL_DOMAIN}
ELEMENT_CALL_SERVER_NAME=element-call
ELEMENT_CALL_URL=https://${CALL_DOMAIN}

IDENTITY_SERVER_URL=https://vector.im

MATRIX_JS_SDK_VERSION=30.0.0
MATRIX_REACT_SDK_VERSION=3.90.0
ELEMENT_WEB_VERSION=1.11.0
ELEMENT_CALL_VERSION=0.5.0

TURN_SERVER_URL=turn:${CALL_DOMAIN}:3478
TURN_USERNAME=
TURN_PASSWORD=
STUN_SERVER_URL=stun:${CALL_DOMAIN}:3478
EOF
    echo "✅ .env файл создан. Пожалуйста, отредактируйте его и укажите:"
    echo "   - Реальный URL вашего Synapse сервера"
    echo "   - Данные TURN сервера (если есть)"
    read -p "Нажмите Enter после редактирования .env файла..."
fi

# Создание директорий
echo "📁 Создание директорий..."
mkdir -p config certs nginx/conf.d builds

# Клонирование репозиториев (если нужно)
if [ ! -d "element-repos" ]; then
    echo "📦 Клонирование репозиториев..."
    chmod +x clone-repos.sh
    ./clone-repos.sh
fi

# Фиксация версий SDK
if [ -f "fix-sdk-versions.sh" ]; then
    echo "🔒 Фиксация версий SDK..."
    chmod +x fix-sdk-versions.sh
    ./fix-sdk-versions.sh
fi

# Проверка SSL сертификатов
echo "🔐 Проверка SSL сертификатов..."
if [ ! -f "certs/fullchain.pem" ] || [ ! -f "certs/privkey.pem" ]; then
    echo "⚠️  SSL сертификаты не найдены в certs/"
    echo "   Получите сертификаты Let's Encrypt:"
    echo "   sudo certbot certonly --standalone -d ${DOMAIN} -d ${CALL_DOMAIN}"
    echo "   Затем скопируйте их в certs/:"
    echo "   sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem certs/"
    echo "   sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem certs/"
    read -p "Нажмите Enter после настройки SSL сертификатов..."
fi

# Обновление конфигурации nginx
echo "⚙️  Обновление конфигурации nginx..."
cat > nginx/conf.d/element.conf << EOF
# Element Web
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://element-web:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# Element Call
server {
    listen 80;
    server_name ${CALL_DOMAIN};

    location / {
        proxy_pass http://element-call:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

echo "✅ Конфигурация обновлена"

# Деплой
echo ""
echo "🚀 Готово к деплою!"
echo ""
echo "Запустите деплой командой:"
echo "  ./deploy.sh docker"
echo ""
echo "Или вручную:"
echo "  docker-compose up -d"
echo ""

