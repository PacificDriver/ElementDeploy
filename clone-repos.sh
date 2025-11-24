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
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || echo "⚠️  Не удалось обновить $repo"
        cd ..
    else
        echo "Клонируем $repo..."
        
        # Используем только HTTPS для публичных репозиториев
        HTTPS_URL="${ELEMENT_ORG}/${repo}.git"
        
        # Пробуем клонировать с отключенным credential helper (для публичных репозиториев не нужен)
        if GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=echo git -c credential.helper= clone --depth=1 "$HTTPS_URL" 2>/dev/null; then
            echo "✅ $repo успешно клонирован через HTTPS"
        elif git clone --depth=1 "$HTTPS_URL" 2>/dev/null; then
            echo "✅ $repo успешно клонирован через HTTPS (с credentials)"
        else
            echo "❌ Ошибка: не удалось клонировать $repo"
            echo ""
            echo "Возможные решения:"
            echo "1. Очистите сохраненные credentials:"
            echo "   git credential reject https://github.com"
            echo "   (затем введите: protocol=https, host=github.com)"
            echo ""
            echo "2. Или клонируйте вручную:"
            echo "   cd $REPOS_DIR"
            echo "   git clone --depth=1 $HTTPS_URL"
            echo ""
            read -p "Продолжить с остальными репозиториями? (y/n): " CONTINUE
            if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
                echo "Прервано пользователем"
                exit 1
            fi
        fi
    fi
done

echo "Все репозитории успешно клонированы в $REPOS_DIR"

