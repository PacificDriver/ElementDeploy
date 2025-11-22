#!/bin/bash

# Скрипт деплоя Element Web и Element Call
# Использование: ./deploy.sh [docker|k8s]

set -e

DEPLOY_TYPE=${1:-docker}
ENV_FILE=${2:-.env}

# Загружаем переменные окружения
if [ -f "$ENV_FILE" ]; then
    echo "Загрузка переменных окружения из $ENV_FILE..."
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
fi

# Проверяем обязательные переменные
if [ -z "$SYNAPSE_BASE_URL" ]; then
    echo "ОШИБКА: SYNAPSE_BASE_URL не установлен"
    echo "Создайте файл .env с необходимыми переменными"
    exit 1
fi

echo "Тип деплоя: $DEPLOY_TYPE"
echo "Synapse URL: $SYNAPSE_BASE_URL"

case $DEPLOY_TYPE in
    docker)
        echo "Деплой через Docker Compose..."
        
        # Создаем директории
        mkdir -p config certs nginx/conf.d builds
        
        # Генерируем конфигурационные файлы с подстановкой переменных
        envsubst < config/element-web-config.json.template > config/element-web-config.json 2>/dev/null || \
            cp config/element-web-config.json config/element-web-config.json.bak
        
        envsubst < config/element-call-config.json.template > config/element-call-config.json 2>/dev/null || \
            cp config/element-call-config.json config/element-call-config.json.bak
        
        # Запускаем Docker Compose
        docker-compose down
        docker-compose pull
        docker-compose up -d
        
        echo "Проверка статуса контейнеров..."
        docker-compose ps
        
        echo "Деплой завершен!"
        echo "Element Web доступен на: http://localhost:8080"
        echo "Element Call доступен на: http://localhost:3000"
        ;;
        
    k8s)
        echo "Деплой через Kubernetes (k3s)..."
        
        # Применяем манифесты
        kubectl apply -f k8s/namespace.yaml
        kubectl apply -f k8s/configmap-element-web.yaml
        kubectl apply -f k8s/configmap-element-call.yaml
        kubectl apply -f k8s/element-web-deployment.yaml
        kubectl apply -f k8s/element-call-deployment.yaml
        kubectl apply -f k8s/ingress.yaml
        
        echo "Ожидание готовности подов..."
        kubectl wait --for=condition=ready pod -l app=element-web -n element --timeout=300s
        kubectl wait --for=condition=ready pod -l app=element-call -n element --timeout=300s
        
        echo "Статус подов:"
        kubectl get pods -n element
        
        echo "Деплой завершен!"
        ;;
        
    *)
        echo "Неизвестный тип деплоя: $DEPLOY_TYPE"
        echo "Использование: ./deploy.sh [docker|k8s] [env-file]"
        exit 1
        ;;
esac

