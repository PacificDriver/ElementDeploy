#!/bin/bash

# Скрипт для обновления SSL сертификатов
# Использование: ./renew-certificates.sh

set -e

echo "🔄 Обновление SSL сертификатов..."
echo ""

# Проверяем наличие docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose не найден"
    exit 1
fi

# Запускаем обновление через certbot контейнер
echo "1️⃣ Проверяем и обновляем сертификаты..."
if docker-compose run --rm certbot renew; then
    echo ""
    echo "2️⃣ Копируем обновленные сертификаты в certs/..."
    
    # Читаем домен из .env если есть
    if [ -f .env ]; then
        DOMAIN=$(grep "^ELEMENT_WEB_DOMAIN=" .env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
        if [ -z "$DOMAIN" ]; then
            DOMAIN=$(grep "^DOMAIN=" .env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
        fi
    fi
    
    # Если домен не найден в .env, пытаемся найти из конфигурации nginx
    if [ -z "$DOMAIN" ] && [ -f nginx/conf.d/element.conf ]; then
        DOMAIN=$(grep "server_name" nginx/conf.d/element.conf | head -1 | sed 's/.*server_name //; s/;.*//' | tr -d ' ')
    fi
    
    if [ -n "$DOMAIN" ]; then
        # Копируем сертификаты
        docker-compose run --rm -v "$(pwd)/certs:/certs" certbot sh -c "
            if [ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
                cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /certs/fullchain.pem && \
                cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem /certs/privkey.pem && \
                chmod 644 /certs/fullchain.pem && \
                chmod 600 /certs/privkey.pem && \
                echo '✅ Сертификаты скопированы'
            else
                echo '⚠️  Сертификаты не найдены в /etc/letsencrypt/live/${DOMAIN}/'
            fi
        "
        
        echo ""
        echo "3️⃣ Перезагружаем nginx..."
        docker-compose restart nginx
        
        echo ""
        echo "✅ Сертификаты обновлены!"
    else
        echo "⚠️  Не удалось определить домен. Сертификаты обновлены, но не скопированы."
        echo "Скопируйте их вручную из /etc/letsencrypt/live/<ваш_домен>/ в папку certs/"
    fi
else
    echo "❌ Ошибка при обновлении сертификатов"
    exit 1
fi

