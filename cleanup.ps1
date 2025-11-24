# PowerShell скрипт полной очистки всех ресурсов
# Использование: .\cleanup.ps1 [-All]
#   -All: удаляет также .env файл и конфигурации

param(
    [switch]$All
)

$ErrorActionPreference = "Continue"

if ($All) {
    Write-Host "⚠️  ВНИМАНИЕ: Будет удален также .env файл и все конфигурации!" -ForegroundColor Yellow
    $confirm = Read-Host "Продолжить? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Отменено." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Очистка ресурсов Element" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Остановка и удаление Docker контейнеров
if (Test-Path "docker-compose.yml") {
    Write-Host "🐳 Остановка Docker контейнеров..." -ForegroundColor Yellow
    try {
        docker-compose down -v 2>$null
        Write-Host "✅ Docker контейнеры остановлены и удалены" -ForegroundColor Green
    } catch {
        Write-Host "   (контейнеры уже остановлены или не существуют)" -ForegroundColor Gray
    }
}

# Удаление Docker volumes
Write-Host "🗑️  Удаление Docker volumes..." -ForegroundColor Yellow
try {
    $volumes = docker volume ls --format "{{.Name}}" | Where-Object { $_ -match "element|123" }
    if ($volumes) {
        $volumes | ForEach-Object { docker volume rm $_ 2>$null }
        Write-Host "✅ Docker volumes удалены" -ForegroundColor Green
    } else {
        Write-Host "   (volumes не найдены)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   (ошибка при удалении volumes)" -ForegroundColor Gray
}

# Удаление клонированных репозиториев
if (Test-Path "element-repos") {
    Write-Host "📦 Удаление клонированных репозиториев..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "element-repos" -ErrorAction SilentlyContinue
    Write-Host "✅ Репозитории удалены" -ForegroundColor Green
}

# Удаление созданных директорий
Write-Host "📁 Удаление созданных директорий..." -ForegroundColor Yellow
$dirsToRemove = @("builds", "certs", ".docker")

foreach ($dir in $dirsToRemove) {
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
        Write-Host "   ✓ Удалена директория: $dir" -ForegroundColor Green
    }
}

# Удаление Kubernetes ресурсов
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Write-Host "☸️  Удаление Kubernetes ресурсов..." -ForegroundColor Yellow
    try {
        $namespace = kubectl get namespace element 2>$null
        if ($namespace) {
            kubectl delete namespace element --ignore-not-found=true 2>$null
            Write-Host "✅ Kubernetes namespace удален" -ForegroundColor Green
        } else {
            Write-Host "   (namespace не найден)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   (ошибка при удалении Kubernetes ресурсов)" -ForegroundColor Gray
    }
}

# Удаление временных файлов
Write-Host "🧹 Удаление временных файлов..." -ForegroundColor Yellow
$filesToRemove = @(
    "versions-lock.json",
    "docker-compose.override.yml",
    ".env.backup"
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item -Force $file -ErrorAction SilentlyContinue
        Write-Host "   ✓ Удален файл: $file" -ForegroundColor Green
    }
}

# Удаление .log файлов
Get-ChildItem -Path . -Filter "*.log" -File -ErrorAction SilentlyContinue | Remove-Item -Force

# Удаление .env файла (если указан -All)
if ($All) {
    if (Test-Path ".env") {
        Write-Host "🗑️  Удаление .env файла..." -ForegroundColor Yellow
        Remove-Item -Force ".env" -ErrorAction SilentlyContinue
        Write-Host "✅ .env файл удален" -ForegroundColor Green
    }
} else {
    Write-Host "ℹ️  .env файл сохранен (используйте -All для полной очистки)" -ForegroundColor Cyan
}

# Очистка Docker образов (опционально)
Write-Host ""
$removeImages = Read-Host "Удалить Docker образы Element? (yes/no)"
if ($removeImages -eq "yes") {
    Write-Host "🗑️  Удаление Docker образов..." -ForegroundColor Yellow
    try {
        $images = docker images --format "{{.ID}}" | Where-Object { 
            $imageInfo = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "element|vectorim"
            $imageInfo
        }
        if ($images) {
            $images | ForEach-Object { docker rmi -f $_ 2>$null }
            Write-Host "✅ Docker образы удалены" -ForegroundColor Green
        } else {
            Write-Host "   (образы не найдены)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   (ошибка при удалении образов)" -ForegroundColor Gray
    }
}

# Очистка неиспользуемых Docker ресурсов
Write-Host ""
$pruneDocker = Read-Host "Очистить неиспользуемые Docker ресурсы? (yes/no)"
if ($pruneDocker -eq "yes") {
    Write-Host "🧹 Очистка Docker..." -ForegroundColor Yellow
    try {
        docker system prune -af --volumes 2>$null
        Write-Host "✅ Docker очищен" -ForegroundColor Green
    } catch {
        Write-Host "   (ошибка при очистке Docker)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Очистка завершена!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Остались файлы:" -ForegroundColor Cyan
Write-Host "  - Конфигурационные файлы (config/, k8s/, nginx/)" -ForegroundColor Gray
Write-Host "  - Скрипты установки и деплоя" -ForegroundColor Gray
Write-Host "  - Документация" -ForegroundColor Gray
if (-not $All) {
    Write-Host "  - .env файл (используйте -All для удаления)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Для полной очистки запустите: .\cleanup.ps1 -All" -ForegroundColor Yellow



