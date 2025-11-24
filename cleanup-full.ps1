# PowerShell скрипт ПОЛНОЙ очистки - удаляет ВСЁ
# ВНИМАНИЕ: Этот скрипт удалит все файлы проекта!
# Использование: .\cleanup-full.ps1

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Red
Write-Host "⚠️  ПОЛНАЯ ОЧИСТКА - УДАЛЕНИЕ ВСЕХ ФАЙЛОВ" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "Этот скрипт удалит:" -ForegroundColor Yellow
Write-Host "  ❌ Все Docker контейнеры и volumes" -ForegroundColor Red
Write-Host "  ❌ Все клонированные репозитории" -ForegroundColor Red
Write-Host "  ❌ Все конфигурационные файлы" -ForegroundColor Red
Write-Host "  ❌ Все скрипты и документацию" -ForegroundColor Red
Write-Host "  ❌ .env файл" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Вы УВЕРЕНЫ? Введите 'DELETE ALL' для подтверждения"

if ($confirm -ne "DELETE ALL") {
    Write-Host "Отменено. Для полной очистки введите точно: DELETE ALL" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Начинаем полную очистку..." -ForegroundColor Yellow

# Остановка Docker
if (Test-Path "docker-compose.yml") {
    docker-compose down -v 2>$null
}

# Удаление всех Docker ресурсов
$volumes = docker volume ls --format "{{.Name}}" | Where-Object { $_ -match "element|123" }
if ($volumes) {
    $volumes | ForEach-Object { docker volume rm $_ 2>$null }
}

# Удаление Kubernetes
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    kubectl delete namespace element --ignore-not-found=true 2>$null
}

# Удаление всей директории проекта
$parentDir = Split-Path -Parent $PWD
$projectDir = Join-Path $parentDir "123"

if (Test-Path $projectDir) {
    Write-Host "Удаление всей директории проекта..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $projectDir
    Write-Host "✅ Всё удалено!" -ForegroundColor Green
} else {
    Write-Host "Директория проекта не найдена" -ForegroundColor Yellow
}



