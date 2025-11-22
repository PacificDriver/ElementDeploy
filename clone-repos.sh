#!/bin/bash

# Скрипт для клонирования репозиториев Element
# Использование: ./clone-repos.sh

set -e

ELEMENT_ORG="https://github.com/element-hq"
REPOS_DIR="./element-repos"

# Создаем директорию для репозиториев
mkdir -p "$REPOS_DIR"
cd "$REPOS_DIR"

echo "Клонирование репозиториев Element..."

# Основные репозитории для веб-клиента
REPOS=(
    "element-web"           # Frontend веб-клиент
    "element-call"          # Backend для RTC/видео звонков
    "matrix-js-sdk"         # JavaScript SDK
    "matrix-react-sdk"      # React SDK
    "matrix-widget-api"     # Widget API
)

# Клонируем каждый репозиторий
for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        echo "Репозиторий $repo уже существует, обновляем..."
        cd "$repo"
        git pull origin main || git pull origin master
        cd ..
    else
        echo "Клонируем $repo..."
        git clone "${ELEMENT_ORG}/${repo}.git"
    fi
done

echo "Все репозитории успешно клонированы в $REPOS_DIR"

