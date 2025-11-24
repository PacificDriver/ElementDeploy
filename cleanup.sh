#!/bin/bash

# Скрипт полной очистки всех ресурсов, созданных скриптами установки
# Использование: ./cleanup.sh [--all]
#   --all: удаляет также .env файл и конфигурации

set -e

REMOVE_ENV=false
if [ "$1" == "--all" ]; then
    REMOVE_ENV=true
    echo "⚠️  ВНИМАНИЕ: Будет удален также .env файл и все конфигурации!"
    read -p "Продолжить? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Отменено."
        exit 0
    fi
fi

echo "=========================================="
echo "Очистка ресурсов Element"
echo "=========================================="

# Остановка и удаление Docker контейнеров
if [ -f "docker-compose.yml" ]; then
    echo "🐳 Остановка Docker контейнеров..."
    docker-compose down -v 2>/dev/null || true
    echo "✅ Docker контейнеры остановлены и удалены"
fi

# Удаление Docker volumes
echo "🗑️  Удаление Docker volumes..."
docker volume ls | grep -E "element|123" | awk '{print $2}' | xargs -r docker volume rm 2>/dev/null || true
echo "✅ Docker volumes удалены"

# Удаление клонированных репозиториев
if [ -d "element-repos" ]; then
    echo "📦 Удаление клонированных репозиториев..."
    rm -rf element-repos
    echo "✅ Репозитории удалены"
fi

# Удаление созданных директорий
echo "📁 Удаление созданных директорий..."
DIRS_TO_REMOVE=(
    "builds"
    "certs"
    ".docker"
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "   ✓ Удалена директория: $dir"
    fi
done

# Удаление Kubernetes ресурсов
if command -v kubectl &> /dev/null; then
    echo "☸️  Удаление Kubernetes ресурсов..."
    if kubectl get namespace element &> /dev/null; then
        kubectl delete namespace element --ignore-not-found=true 2>/dev/null || true
        echo "✅ Kubernetes namespace удален"
    fi
fi

# Удаление временных файлов
echo "🧹 Удаление временных файлов..."
FILES_TO_REMOVE=(
    "versions-lock.json"
    "docker-compose.override.yml"
    ".env.backup"
    "*.log"
)

for pattern in "${FILES_TO_REMOVE[@]}"; do
    find . -maxdepth 1 -name "$pattern" -type f -delete 2>/dev/null || true
done

# Удаление .env файла (если указан --all)
if [ "$REMOVE_ENV" = true ]; then
    if [ -f ".env" ]; then
        echo "🗑️  Удаление .env файла..."
        rm -f .env
        echo "✅ .env файл удален"
    fi
else
    echo "ℹ️  .env файл сохранен (используйте --all для полной очистки)"
fi

# Очистка Docker образов (опционально)
echo ""
read -p "Удалить Docker образы Element? (yes/no): " remove_images
if [ "$remove_images" == "yes" ]; then
    echo "🗑️  Удаление Docker образов..."
    docker images | grep -E "element|vectorim" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    echo "✅ Docker образы удалены"
fi

# Очистка неиспользуемых Docker ресурсов
echo ""
read -p "Очистить неиспользуемые Docker ресурсы? (yes/no): " prune_docker
if [ "$prune_docker" == "yes" ]; then
    echo "🧹 Очистка Docker..."
    docker system prune -af --volumes 2>/dev/null || true
    echo "✅ Docker очищен"
fi

echo ""
echo "=========================================="
echo "✅ Очистка завершена!"
echo "=========================================="
echo ""
echo "Остались файлы:"
echo "  - Конфигурационные файлы (config/, k8s/, nginx/)"
echo "  - Скрипты установки и деплоя"
echo "  - Документация"
if [ "$REMOVE_ENV" != true ]; then
    echo "  - .env файл (используйте --all для удаления)"
fi
echo ""
echo "Для полной очистки запустите: ./cleanup.sh --all"



