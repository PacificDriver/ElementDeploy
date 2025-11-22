#!/bin/bash

# Скрипт для клонирования репозиториев Element
# Использование: ./clone-repos.sh

# Не используем set -e, чтобы обрабатывать ошибки клонирования

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
        # Отключаем credential helper для клонирования публичных репозиториев без пароля
        GIT_TERMINAL_PROMPT=0 git -c credential.helper= clone "${ELEMENT_ORG}/${repo}.git" 2>/dev/null || \
        git clone "git@github.com:element-hq/${repo}.git" || {
            echo "Ошибка: не удалось клонировать $repo"
            echo "Попробуйте очистить сохраненные credentials: git credential reject https://github.com"
        }
    fi
done

echo "Все репозитории успешно клонированы в $REPOS_DIR"

