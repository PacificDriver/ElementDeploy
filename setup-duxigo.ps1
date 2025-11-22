# PowerShell скрипт автоматической настройки для Element
# Использование: .\setup-duxigo.ps1

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Настройка Element" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Запрос домена у пользователя
Write-Host "Введите данные для настройки:" -ForegroundColor Yellow
Write-Host ""

$DOMAIN = Read-Host "Домен для Element Web (например: test.duxigo.org)"
while ([string]::IsNullOrWhiteSpace($DOMAIN)) {
    Write-Host "Домен не может быть пустым!" -ForegroundColor Red
    $DOMAIN = Read-Host "Домен для Element Web (например: test.duxigo.org)"
}

$defaultCallDomain = "call.$DOMAIN"
$CALL_DOMAIN = Read-Host "Домен для Element Call [$defaultCallDomain]"
if ([string]::IsNullOrWhiteSpace($CALL_DOMAIN)) {
    $CALL_DOMAIN = $defaultCallDomain
}

Write-Host ""
Write-Host "Введите данные Synapse сервера:" -ForegroundColor Yellow
$SYNAPSE_BASE_URL = Read-Host "URL Synapse сервера (например: https://synapse.test.duxigo.org)"
while ([string]::IsNullOrWhiteSpace($SYNAPSE_BASE_URL)) {
    Write-Host "URL Synapse не может быть пустым!" -ForegroundColor Red
    $SYNAPSE_BASE_URL = Read-Host "URL Synapse сервера (например: https://synapse.test.duxigo.org)"
}

# Парсим домен из URL для SYNAPSE_HOST
if ($SYNAPSE_BASE_URL -match 'https?://([^/]+)') {
    $SYNAPSE_DOMAIN = $matches[1]
} else {
    $SYNAPSE_DOMAIN = $SYNAPSE_BASE_URL -replace 'https?://', ''
}

$SYNAPSE_SERVER_NAME = Read-Host "Имя сервера Synapse [$DOMAIN]"
if ([string]::IsNullOrWhiteSpace($SYNAPSE_SERVER_NAME)) {
    $SYNAPSE_SERVER_NAME = $DOMAIN
}

Write-Host ""
Write-Host "Опциональные настройки (можно оставить пустыми):" -ForegroundColor Yellow
$TURN_USERNAME = Read-Host "TURN сервер - имя пользователя"
$TURN_PASSWORD_INPUT = Read-Host "TURN сервер - пароль"
$TURN_PASSWORD_PLAIN = ""
if (-not [string]::IsNullOrWhiteSpace($TURN_PASSWORD_INPUT)) {
    $TURN_PASSWORD_PLAIN = $TURN_PASSWORD_INPUT
}

$MAPTILER_KEY = Read-Host "MapTiler API Key (для карт)"

Write-Host ""
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
    
    $envContent = @"
# Конфигурация для $DOMAIN
SYNAPSE_BASE_URL=$SYNAPSE_BASE_URL
SYNAPSE_SERVER_NAME=$SYNAPSE_SERVER_NAME
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
"@

    if (-not [string]::IsNullOrWhiteSpace($TURN_USERNAME)) {
        $envContent += "`nTURN_USERNAME=$TURN_USERNAME"
    } else {
        $envContent += "`nTURN_USERNAME="
    }
    
    if (-not [string]::IsNullOrWhiteSpace($TURN_PASSWORD_PLAIN)) {
        $envContent += "`nTURN_PASSWORD=$TURN_PASSWORD_PLAIN"
    } else {
        $envContent += "`nTURN_PASSWORD="
    }
    
    $envContent += "`nSTUN_SERVER_URL=stun:$CALL_DOMAIN:3478"
    
    if (-not [string]::IsNullOrWhiteSpace($MAPTILER_KEY)) {
        $envContent += "`nMAPTILER_KEY=$MAPTILER_KEY"
    }
    
    $envContent | Out-File -FilePath .env -Encoding UTF8
    
    Write-Host "✅ .env файл создан с указанными параметрами" -ForegroundColor Green
} else {
    Write-Host "⚠️  Файл .env уже существует, пропускаем создание" -ForegroundColor Yellow
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

# Проверка SSL сертификатов
Write-Host "🔐 Проверка SSL сертификатов..." -ForegroundColor Green
if (-not (Test-Path "certs\fullchain.pem") -or -not (Test-Path "certs\privkey.pem")) {
    Write-Host "⚠️  SSL сертификаты не найдены в certs/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Для получения SSL сертификатов Let's Encrypt выполните:" -ForegroundColor Cyan
    Write-Host "   certbot certonly --standalone -d $DOMAIN -d $CALL_DOMAIN" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Затем скопируйте сертификаты в папку certs/:" -ForegroundColor Cyan
    Write-Host "   copy C:\etc\letsencrypt\live\$DOMAIN\fullchain.pem certs\" -ForegroundColor Yellow
    Write-Host "   copy C:\etc\letsencrypt\live\$DOMAIN\privkey.pem certs\" -ForegroundColor Yellow
    Write-Host ""
    $sslReady = Read-Host "Нажмите Enter после настройки SSL сертификатов (или если пропускаете этот шаг)"
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

