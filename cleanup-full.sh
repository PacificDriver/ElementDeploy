#!/bin/bash

# Скрипт ПОЛНОЙ очистки - удаляет ВСЁ включая конфигурации
# ВНИМАНИЕ: Этот скрипт удалит все файлы проекта!
# Использование: ./cleanup-full.sh

set -e

echo "=========================================="
echo "⚠️  ПОЛНАЯ ОЧИСТКА - УДАЛЕНИЕ ВСЕХ ФАЙЛОВ"
echo "=========================================="
echo ""
echo "Этот скрипт удалит:"
echo "  ❌ Все Docker контейнеры и volumes"
echo "  ❌ Все клонированные репозитории"
echo "  ❌ Все конфигурационные файлы"
echo "  ❌ Все скрипты и документацию"
echo "  ❌ .env файл"
echo ""
read -p "Вы УВЕРЕНЫ? Введите 'DELETE ALL' для подтверждения: " confirm

if [ "$confirm" != "DELETE ALL" ]; then
    echo "Отменено. Для полной очистки введите точно: DELETE ALL"
    exit 0
fi

echo ""
echo "Начинаем полную очистку..."

# Остановка Docker
if [ -f "docker-compose.yml" ]; then
    docker-compose down -v 2>/dev/null || true
fi

# Удаление всех Docker ресурсов
docker volume ls | grep -E "element|123" | awk '{print $2}' | xargs -r docker volume rm 2>/dev/null || true

# Удаление Kubernetes
if command -v kubectl &> /dev/null; then
    kubectl delete namespace element --ignore-not-found=true 2>/dev/null || true
fi

# Удаление всех директорий проекта
cd ..
if [ -d "123" ]; then
    echo "Удаление всей директории проекта..."
    rm -rf 123
    echo "✅ Всё удалено!"
else
    echo "Директория проекта не найдена"
fi



