#!/bin/bash

# Скрипт для проверки взаимодействия с Element X и Synapse
# Использование: ./test-connection.sh

set -e

ENV_FILE=${1:-.env}

# Загружаем переменные окружения
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
fi

SYNAPSE_URL=${SYNAPSE_BASE_URL:-https://synapse.example.com}
ELEMENT_WEB_URL=${ELEMENT_WEB_URL:-http://localhost:8080}
ELEMENT_CALL_URL=${ELEMENT_CALL_URL:-http://localhost:3000}

echo "Проверка взаимодействия с Element и Synapse..."
echo "================================================"

# Проверка доступности Synapse
echo "1. Проверка Synapse сервера..."
if command -v curl &> /dev/null; then
    SYNAPSE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SYNAPSE_URL/_matrix/client/versions" || echo "000")
    if [ "$SYNAPSE_STATUS" = "200" ]; then
        echo "   ✓ Synapse доступен ($SYNAPSE_STATUS)"
        curl -s "$SYNAPSE_URL/_matrix/client/versions" | head -20
    else
        echo "   ✗ Synapse недоступен (код: $SYNAPSE_STATUS)"
    fi
else
    echo "   ⚠ curl не установлен, пропускаем проверку"
fi

# Проверка Element Web
echo ""
echo "2. Проверка Element Web..."
if command -v curl &> /dev/null; then
    ELEMENT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$ELEMENT_WEB_URL" || echo "000")
    if [ "$ELEMENT_STATUS" = "200" ]; then
        echo "   ✓ Element Web доступен ($ELEMENT_STATUS)"
    else
        echo "   ✗ Element Web недоступен (код: $ELEMENT_STATUS)"
    fi
else
    echo "   ⚠ curl не установлен, пропускаем проверку"
fi

# Проверка Element Call
echo ""
echo "3. Проверка Element Call..."
if command -v curl &> /dev/null; then
    CALL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$ELEMENT_CALL_URL/health" || echo "000")
    if [ "$CALL_STATUS" = "200" ]; then
        echo "   ✓ Element Call доступен ($CALL_STATUS)"
    else
        echo "   ✗ Element Call недоступен (код: $CALL_STATUS)"
    fi
else
    echo "   ⚠ curl не установлен, пропускаем проверку"
fi

# Проверка версий SDK
echo ""
echo "4. Проверка версий SDK..."
if [ -f "versions-lock.json" ]; then
    echo "   ✓ Файл versions-lock.json найден:"
    cat versions-lock.json | grep -A 5 "locked_versions" || cat versions-lock.json
else
    echo "   ⚠ Файл versions-lock.json не найден"
fi

# Проверка RTC конфигурации
echo ""
echo "5. Проверка RTC конфигурации..."
if [ -f "versions-lock.json" ]; then
    echo "   RTC настройки:"
    cat versions-lock.json | grep -A 3 "rtc_config" || echo "   RTC конфигурация не найдена"
fi

# Проверка Docker контейнеров (если используется Docker)
echo ""
echo "6. Проверка Docker контейнеров..."
if command -v docker &> /dev/null && [ -f "docker-compose.yml" ]; then
    if docker-compose ps | grep -q "Up"; then
        echo "   ✓ Контейнеры запущены:"
        docker-compose ps
    else
        echo "   ✗ Контейнеры не запущены"
    fi
fi

# Проверка Kubernetes подов (если используется k8s)
echo ""
echo "7. Проверка Kubernetes подов..."
if command -v kubectl &> /dev/null; then
    if kubectl get namespace element &> /dev/null; then
        echo "   ✓ Namespace element существует:"
        kubectl get pods -n element
    else
        echo "   ⚠ Namespace element не найден"
    fi
fi

echo ""
echo "================================================"
echo "Проверка завершена!"

