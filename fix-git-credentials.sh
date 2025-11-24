#!/bin/bash

# Скрипт для исправления проблем с Git credentials
# Использование: ./fix-git-credentials.sh

echo "🔧 Исправление проблем с Git credentials..."
echo ""

echo "Попытка 1: Очистка credential helper..."
git credential reject <<EOF
protocol=https
host=github.com
EOF

echo ""
echo "Попытка 2: Очистка через credential-manager-core (если установлен)..."
git credential-manager-core erase <<EOF
protocol=https
host=github.com
EOF

echo ""
echo "Попытка 3: Очистка через credential.helper..."
git config --global --unset credential.helper 2>/dev/null || true
git config --unset credential.helper 2>/dev/null || true

echo ""
echo "✅ Credentials очищены"
echo ""
echo "Теперь попробуйте снова:"
echo "  ./clone-repos.sh"

