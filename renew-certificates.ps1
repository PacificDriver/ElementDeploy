# PowerShell скрипт для обновления SSL сертификатов
# Использование: .\renew-certificates.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔄 Обновление SSL сертификатов..." -ForegroundColor Cyan
Write-Host ""

# Проверяем наличие docker-compose
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ docker-compose не найден" -ForegroundColor Red
    exit 1
}

# Запускаем обновление через certbot контейнер
Write-Host "1️⃣ Проверяем и обновляем сертификаты..." -ForegroundColor Green

try {
    docker-compose run --rm certbot renew
    
    Write-Host ""
    Write-Host "2️⃣ Копируем обновленные сертификаты в certs/..." -ForegroundColor Green
    
    # Читаем домен из .env если есть
    $DOMAIN = $null
    if (Test-Path .env) {
        $envContent = Get-Content .env
        $domainLine = $envContent | Where-Object { $_ -match "^ELEMENT_WEB_DOMAIN=(.+)" }
        if ($domainLine) {
            $DOMAIN = $matches[1].Trim().Trim('"').Trim("'")
        }
        if (-not $DOMAIN) {
            $domainLine = $envContent | Where-Object { $_ -match "^DOMAIN=(.+)" }
            if ($domainLine) {
                $DOMAIN = $matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }
    
    # Если домен не найден в .env, пытаемся найти из конфигурации nginx
    if (-not $DOMAIN -and (Test-Path "nginx\conf.d\element.conf")) {
        $nginxConfig = Get-Content "nginx\conf.d\element.conf" -Raw
        if ($nginxConfig -match 'server_name\s+([^\s;]+)') {
            $DOMAIN = $matches[1].Trim()
        }
    }
    
    if ($DOMAIN) {
        # Копируем сертификаты
        $currentDir = (Get-Location).Path
        docker-compose run --rm -v "${currentDir}/certs:/certs" certbot sh -c "
            if [ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
                cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /certs/fullchain.pem && \
                cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem /certs/privkey.pem && \
                chmod 644 /certs/fullchain.pem && \
                chmod 600 /certs/privkey.pem && \
                echo '✅ Сертификаты скопированы'
            else
                echo '⚠️  Сертификаты не найдены в /etc/letsencrypt/live/${DOMAIN}/'
            fi
        "
        
        Write-Host ""
        Write-Host "3️⃣ Перезагружаем nginx..." -ForegroundColor Green
        docker-compose restart nginx
        
        Write-Host ""
        Write-Host "✅ Сертификаты обновлены!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Не удалось определить домен. Сертификаты обновлены, но не скопированы." -ForegroundColor Yellow
        Write-Host "Скопируйте их вручную из /etc/letsencrypt/live/<ваш_домен>/ в папку certs/" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Ошибка при обновлении сертификатов: $_" -ForegroundColor Red
    exit 1
}

