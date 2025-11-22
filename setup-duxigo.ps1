# PowerShell скрипт автоматической настройки для test.duxigo.org
# Использование: .\setup-duxigo.ps1

$ErrorActionPreference = "Stop"

$DOMAIN = "test.duxigo.org"
$CALL_DOMAIN = "call.test.duxigo.org"
$SYNAPSE_DOMAIN = "synapse.test.duxigo.org"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Настройка Element для $DOMAIN" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Проверка Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker не установлен" -ForegroundColor Red
    Write-Host "Установите Docker Desktop для Windows: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Проверка Docker Compose
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Compose не установлен" -ForegroundColor Red
    Write-Host "Docker Compose должен быть включен в Docker Desktop" -ForegroundColor Yellow
    exit 1
}

# Создание .env файла
if (-not (Test-Path .env)) {
    Write-Host "📝 Создание .env файла..." -ForegroundColor Green
    @"
# Конфигурация для test.duxigo.org
SYNAPSE_BASE_URL=https://$SYNAPSE_DOMAIN
SYNAPSE_SERVER_NAME=$DOMAIN
SYNAPSE_HOST=$SYNAPSE_DOMAIN

ELEMENT_WEB_DOMAIN=$DOMAIN
ELEMENT_WEB_URL=https://$DOMAIN

ELEMENT_CALL_BASE_URL=https://$CALL_DOMAIN
ELEMENT_CALL_SERVER_NAME=element-call
ELEMENT_CALL_URL=https://$CALL_DOMAIN

IDENTITY_SERVER_URL=https://vector.im

MATRIX_JS_SDK_VERSION=30.0.0
MATRIX_REACT_SDK_VERSION=3.90.0
ELEMENT_WEB_VERSION=1.11.0
ELEMENT_CALL_VERSION=0.5.0

TURN_SERVER_URL=turn:$CALL_DOMAIN:3478
TURN_USERNAME=
TURN_PASSWORD=
STUN_SERVER_URL=stun:$CALL_DOMAIN:3478
"@ | Out-File -FilePath .env -Encoding UTF8
    
    Write-Host "✅ .env файл создан. Пожалуйста, отредактируйте его и укажите:" -ForegroundColor Green
    Write-Host "   - Реальный URL вашего Synapse сервера" -ForegroundColor Yellow
    Write-Host "   - Данные TURN сервера (если есть)" -ForegroundColor Yellow
    Read-Host "Нажмите Enter после редактирования .env файла"
}

# Создание директорий
Write-Host "📁 Создание директорий..." -ForegroundColor Green
@("config", "certs", "nginx\conf.d", "builds") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }
}

# Клонирование репозиториев (если нужно)
if (-not (Test-Path "element-repos")) {
    Write-Host "📦 Клонирование репозиториев..." -ForegroundColor Green
    if (Test-Path "clone-repos.ps1") {
        .\clone-repos.ps1
    }
}

# Фиксация версий SDK
if (Test-Path "fix-sdk-versions.ps1") {
    Write-Host "🔒 Фиксация версий SDK..." -ForegroundColor Green
    .\fix-sdk-versions.ps1
}

# Обновление конфигурации nginx
Write-Host "⚙️  Обновление конфигурации nginx..." -ForegroundColor Green
$nginxConfig = @"
# Element Web
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://element-web:80;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }
}

# Element Call
server {
    listen 80;
    server_name $CALL_DOMAIN;

    location / {
        proxy_pass http://element-call:3000;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
"@

$nginxConfig | Out-File -FilePath "nginx\conf.d\element.conf" -Encoding UTF8

Write-Host "✅ Конфигурация обновлена" -ForegroundColor Green

Write-Host ""
Write-Host "🚀 Готово к деплою!" -ForegroundColor Green
Write-Host ""
Write-Host "Запустите деплой командой:" -ForegroundColor Cyan
Write-Host "  .\deploy.ps1 docker" -ForegroundColor Yellow
Write-Host ""
Write-Host "Или вручную:" -ForegroundColor Cyan
Write-Host "  docker-compose up -d" -ForegroundColor Yellow
Write-Host ""

