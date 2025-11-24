#!/bin/bash

# Автоматический скрипт настройки для Element
# Использование: ./setup-duxigo.sh

set -e

echo "=========================================="
echo "Настройка Element"
echo "=========================================="
echo ""

# Запрос домена у пользователя
echo "Введите данные для настройки:"
echo ""

read -p "Домен для Element Web (например: test.duxigo.org): " DOMAIN
while [ -z "$DOMAIN" ]; do
    echo "Домен не может быть пустым!"
    read -p "Домен для Element Web (например: test.duxigo.org): " DOMAIN
done

DEFAULT_CALL_DOMAIN="call.$DOMAIN"
read -p "Домен для Element Call [$DEFAULT_CALL_DOMAIN]: " CALL_DOMAIN
if [ -z "$CALL_DOMAIN" ]; then
    CALL_DOMAIN="$DEFAULT_CALL_DOMAIN"
fi

echo ""
echo "Введите данные Synapse сервера:"
read -p "URL Synapse сервера (например: https://synapse.test.duxigo.org): " SYNAPSE_BASE_URL
while [ -z "$SYNAPSE_BASE_URL" ]; do
    echo "URL Synapse не может быть пустым!"
    read -p "URL Synapse сервера (например: https://synapse.test.duxigo.org): " SYNAPSE_BASE_URL
done

# Парсим домен из URL для SYNAPSE_HOST
SYNAPSE_DOMAIN=$(echo "$SYNAPSE_BASE_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

read -p "Имя сервера Synapse [$DOMAIN]: " SYNAPSE_SERVER_NAME
if [ -z "$SYNAPSE_SERVER_NAME" ]; then
    SYNAPSE_SERVER_NAME="$DOMAIN"
fi

echo ""
echo "Опциональные настройки (можно оставить пустыми):"
read -p "TURN сервер - имя пользователя: " TURN_USERNAME
read -sp "TURN сервер - пароль: " TURN_PASSWORD
echo ""
read -p "MapTiler API Key (для карт): " MAPTILER_KEY

echo ""
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
# Конфигурация для ${DOMAIN}
SYNAPSE_BASE_URL=${SYNAPSE_BASE_URL}
SYNAPSE_SERVER_NAME=${SYNAPSE_SERVER_NAME}
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
TURN_USERNAME=${TURN_USERNAME}
TURN_PASSWORD=${TURN_PASSWORD}
STUN_SERVER_URL=stun:${CALL_DOMAIN}:3478
EOF

    if [ -n "$MAPTILER_KEY" ]; then
        echo "MAPTILER_KEY=${MAPTILER_KEY}" >> .env
    fi

    echo "✅ .env файл создан с указанными параметрами"
else
    echo "⚠️  Файл .env уже существует, пропускаем создание"
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
    echo ""
    echo "🚀 Автоматическое получение SSL сертификатов через Docker..."
    echo ""
    
    # Запрашиваем email для Let's Encrypt
    read -p "Введите email для уведомлений Let's Encrypt (необязательно, Enter чтобы пропустить): " CERT_EMAIL
    
    echo ""
    echo "📋 Убедитесь, что домены ${DOMAIN} и ${CALL_DOMAIN} указывают на этот сервер (DNS)"
    echo ""
    read -p "Запустить автоматическое получение сертификатов сейчас? (y/n): " GET_CERTS_NOW
    
    if [ "$GET_CERTS_NOW" = "y" ] || [ "$GET_CERTS_NOW" = "Y" ]; then
        echo ""
        echo "1️⃣ Запускаем nginx в режиме HTTP для ACME challenge..."
        
        # Запускаем только nginx для ACME challenge
        docker-compose up -d nginx 2>/dev/null || docker-compose up -d nginx
        
        # Ждем запуска nginx
        echo "⏳ Ожидание запуска nginx..."
        sleep 5
        
        # Запускаем certbot в контейнере
        echo "2️⃣ Получаем сертификаты через certbot..."
        
        CERTBOT_CMD="certbot certonly --webroot --webroot-path=/var/www/certbot --agree-tos --non-interactive"
        
        if [ -n "$CERT_EMAIL" ]; then
            CERTBOT_CMD="$CERTBOT_CMD --email $CERT_EMAIL"
        else
            CERTBOT_CMD="$CERTBOT_CMD --register-unsafely-without-email"
        fi
        
        CERTBOT_CMD="$CERTBOT_CMD -d $DOMAIN -d $CALL_DOMAIN"
        
        if docker-compose run --rm certbot $CERTBOT_CMD; then
            echo "✅ Сертификаты успешно получены!"
            
            # Копируем сертификаты из volume в папку certs/
            echo "3️⃣ Копируем сертификаты в папку certs/..."
            
            # Используем временный контейнер для копирования
            docker-compose run --rm -v "$(pwd)/certs:/certs" certbot sh -c "
                cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /certs/fullchain.pem && \
                cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem /certs/privkey.pem && \
                chmod 644 /certs/fullchain.pem && \
                chmod 600 /certs/privkey.pem
            " || {
                # Альтернативный способ - через docker cp
                CERT_CONTAINER=$(docker-compose ps -q certbot 2>/dev/null || echo "")
                if [ -z "$CERT_CONTAINER" ]; then
                    CERT_CONTAINER=$(docker-compose run -d certbot sleep 60)
                    sleep 2
                fi
                
                docker cp ${CERT_CONTAINER}:/etc/letsencrypt/live/${DOMAIN}/fullchain.pem certs/fullchain.pem 2>/dev/null || true
                docker cp ${CERT_CONTAINER}:/etc/letsencrypt/live/${DOMAIN}/privkey.pem certs/privkey.pem 2>/dev/null || true
                
                if [ -n "$CERT_CONTAINER" ]; then
                    docker stop $CERT_CONTAINER 2>/dev/null || true
                    docker rm $CERT_CONTAINER 2>/dev/null || true
                fi
            }
            
            if [ -f "certs/fullchain.pem" ] && [ -f "certs/privkey.pem" ]; then
                echo "✅ Сертификаты скопированы в certs/"
                
                # Обновляем nginx конфигурацию для HTTPS
                echo "4️⃣ Обновляем конфигурацию nginx для HTTPS..."
                # Перезагружаем конфигурацию nginx - она уже будет содержать SSL, так как сертификаты теперь есть
                docker-compose restart nginx
                
                echo ""
                echo "✅ Готово! SSL сертификаты получены и настроены."
                echo "🌐 Ваши сервисы теперь доступны по HTTPS:"
                echo "   - https://${DOMAIN}"
                echo "   - https://${CALL_DOMAIN}"
                echo ""
                echo "💡 Сертификаты будут автоматически обновляться каждые 12 часов контейнером certbot"
            else
                echo "⚠️  Не удалось скопировать сертификаты автоматически"
                echo "Попробуйте вручную:"
                echo "  docker-compose exec certbot cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /certs/"
                echo "  docker-compose exec certbot cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem /certs/"
            fi
        else
            echo "❌ Ошибка при получении сертификатов"
            echo ""
            echo "Возможные причины:"
            echo "  - Домены не указывают на этот сервер (проверьте DNS)"
            echo "  - Порты 80 и 443 уже заняты"
            echo "  - Сервер недоступен из интернета"
            echo ""
            echo "Вы можете попробовать позже командой:"
            echo "  docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot -d ${DOMAIN} -d ${CALL_DOMAIN}"
        fi
    else
        echo ""
        echo "⚠️  Получение сертификатов пропущено."
        echo "После настройки DNS запустите:"
        echo "  docker-compose up -d nginx"
        echo "  docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot -d ${DOMAIN} -d ${CALL_DOMAIN}"
    fi
else
    echo "✅ SSL сертификаты уже существуют"
fi

# Обновление конфигурации nginx
echo "⚙️  Обновление конфигурации nginx..."

# Проверяем наличие сертификатов для определения какой конфигурации использовать
if [ -f "certs/fullchain.pem" ] && [ -f "certs/privkey.pem" ]; then
    # Сертификаты уже есть - используем HTTPS конфигурацию
    cat > nginx/conf.d/element.conf << EOF
# ACME Challenge для обновления сертификатов
server {
    listen 80;
    server_name ${DOMAIN} ${CALL_DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

# Element Web - HTTPS
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://element-web:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# Element Call - HTTPS
server {
    listen 443 ssl http2;
    server_name ${CALL_DOMAIN};

    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

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
else
    # Сертификатов нет - используем HTTP конфигурацию с поддержкой ACME challenge
    cat > nginx/conf.d/element.conf << EOF
# Временная конфигурация для получения SSL сертификатов
# ACME Challenge
server {
    listen 80;
    server_name ${DOMAIN} ${CALL_DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Element Web
    location / {
        if (\$host = ${DOMAIN}) {
            proxy_pass http://element-web:80;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }

    # Element Call
    location / {
        if (\$host = ${CALL_DOMAIN}) {
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
}
EOF
fi

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
echo "📝 Примечания:"
echo "  - SSL сертификаты будут автоматически обновляться каждые 12 часов"
echo "  - Для ручного обновления: ./renew-certificates.sh"
echo ""

