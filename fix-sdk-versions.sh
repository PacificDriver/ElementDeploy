#!/bin/bash

# Скрипт для фиксации версий SDK и RTC конфигурации
# Использование: ./fix-sdk-versions.sh

set -e

REPOS_DIR="./element-repos"
ENV_FILE=".env"

# Загружаем версии из .env
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Версии по умолчанию (если не указаны в .env)
MATRIX_JS_SDK_VERSION=${MATRIX_JS_SDK_VERSION:-"30.0.0"}
MATRIX_REACT_SDK_VERSION=${MATRIX_REACT_SDK_VERSION:-"3.90.0"}
ELEMENT_WEB_VERSION=${ELEMENT_WEB_VERSION:-"1.11.0"}
ELEMENT_CALL_VERSION=${ELEMENT_CALL_VERSION:-"0.5.0"}

echo "Фиксация версий SDK и RTC конфигурации..."
echo "Matrix JS SDK: $MATRIX_JS_SDK_VERSION"
echo "Matrix React SDK: $MATRIX_REACT_SDK_VERSION"
echo "Element Web: $ELEMENT_WEB_VERSION"
echo "Element Call: $ELEMENT_CALL_VERSION"

cd "$REPOS_DIR" || exit 1

# Фиксируем версии в element-web
if [ -d "element-web" ]; then
    echo "Обновление версий в element-web..."
    cd element-web
    
    # Переключаемся на нужную версию
    git fetch --tags
    git checkout "v${ELEMENT_WEB_VERSION}" 2>/dev/null || git checkout "$ELEMENT_WEB_VERSION"
    
    # Обновляем package.json для фиксации версий зависимостей
    if [ -f "package.json" ]; then
        # Используем sed для обновления версий (если доступен)
        if command -v sed &> /dev/null; then
            sed -i.bak "s/\"matrix-js-sdk\": \".*\"/\"matrix-js-sdk\": \"${MATRIX_JS_SDK_VERSION}\"/" package.json
            sed -i.bak "s/\"matrix-react-sdk\": \".*\"/\"matrix-react-sdk\": \"${MATRIX_REACT_SDK_VERSION}\"/" package.json
        fi
    fi
    
    cd ..
fi

# Фиксируем версии в matrix-js-sdk
if [ -d "matrix-js-sdk" ]; then
    echo "Обновление версий в matrix-js-sdk..."
    cd matrix-js-sdk
    git fetch --tags
    git checkout "v${MATRIX_JS_SDK_VERSION}" 2>/dev/null || git checkout "$MATRIX_JS_SDK_VERSION"
    cd ..
fi

# Фиксируем версии в matrix-react-sdk
if [ -d "matrix-react-sdk" ]; then
    echo "Обновление версий в matrix-react-sdk..."
    cd matrix-react-sdk
    git fetch --tags
    git checkout "v${MATRIX_REACT_SDK_VERSION}" 2>/dev/null || git checkout "$MATRIX_REACT_SDK_VERSION"
    cd ..
fi

# Фиксируем версии в element-call
if [ -d "element-call" ]; then
    echo "Обновление версий в element-call..."
    cd element-call
    git fetch --tags
    git checkout "v${ELEMENT_CALL_VERSION}" 2>/dev/null || git checkout "$ELEMENT_CALL_VERSION"
    cd ..
fi

cd ..

echo "Версии SDK зафиксированы!"
echo "Создаем файл с информацией о версиях..."

# Создаем файл с информацией о версиях
cat > versions-lock.json << EOF
{
  "locked_versions": {
    "matrix-js-sdk": "${MATRIX_JS_SDK_VERSION}",
    "matrix-react-sdk": "${MATRIX_REACT_SDK_VERSION}",
    "element-web": "${ELEMENT_WEB_VERSION}",
    "element-call": "${ELEMENT_CALL_VERSION}",
    "lock_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "rtc_config": {
    "turn_server": "${TURN_SERVER_URL:-not_configured}",
    "stun_server": "${STUN_SERVER_URL:-not_configured}"
  }
}
EOF

echo "Информация о версиях сохранена в versions-lock.json"

