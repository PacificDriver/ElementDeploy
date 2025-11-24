# PowerShell скрипт для исправления проблем с Git credentials
# Использование: .\fix-git-credentials.ps1

Write-Host "🔧 Исправление проблем с Git credentials..." -ForegroundColor Cyan
Write-Host ""

Write-Host "Попытка 1: Очистка credential helper..." -ForegroundColor Yellow
try {
    "protocol=https`nhost=github.com" | git credential reject 2>&1 | Out-Null
} catch {
    # Игнорируем ошибки
}

Write-Host ""
Write-Host "Попытка 2: Очистка через credential-manager-core (если установлен)..." -ForegroundColor Yellow
try {
    "protocol=https`nhost=github.com" | git credential-manager-core erase 2>&1 | Out-Null
} catch {
    # Игнорируем ошибки
}

Write-Host ""
Write-Host "Попытка 3: Очистка через git config..." -ForegroundColor Yellow
git config --global --unset credential.helper 2>$null
git config --unset credential.helper 2>$null

Write-Host ""
Write-Host "✅ Credentials очищены" -ForegroundColor Green
Write-Host ""
Write-Host "Теперь попробуйте снова:" -ForegroundColor Cyan
Write-Host "  .\clone-repos.ps1" -ForegroundColor Yellow

