# PowerShell скрипт для проверки взаимодействия с Element X и Synapse
# Использование: .\test-connection.ps1 [env-file]

param(
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Continue"

# Загружаем переменные окружения
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Variable -Name $name -Value $value -Scope Script
        }
    }
}

$SYNAPSE_URL = if ($SYNAPSE_BASE_URL) { $SYNAPSE_BASE_URL } else { "https://synapse.example.com" }
$ELEMENT_WEB_URL = if ($ELEMENT_WEB_URL) { $ELEMENT_WEB_URL } else { "http://localhost:8080" }
$ELEMENT_CALL_URL = if ($ELEMENT_CALL_URL) { $ELEMENT_CALL_URL } else { "http://localhost:3000" }

Write-Host "Проверка взаимодействия с Element и Synapse..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Проверка доступности Synapse
Write-Host "1. Проверка Synapse сервера..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$SYNAPSE_URL/_matrix/client/versions" -Method Get -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Synapse доступен ($($response.StatusCode))" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | Format-List
} catch {
    Write-Host "   ✗ Synapse недоступен: $($_.Exception.Message)" -ForegroundColor Red
}

# Проверка Element Web
Write-Host ""
Write-Host "2. Проверка Element Web..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $ELEMENT_WEB_URL -Method Get -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Element Web доступен ($($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Element Web недоступен: $($_.Exception.Message)" -ForegroundColor Red
}

# Проверка Element Call
Write-Host ""
Write-Host "3. Проверка Element Call..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$ELEMENT_CALL_URL/health" -Method Get -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Element Call доступен ($($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Element Call недоступен: $($_.Exception.Message)" -ForegroundColor Red
}

# Проверка версий SDK
Write-Host ""
Write-Host "4. Проверка версий SDK..." -ForegroundColor Cyan
if (Test-Path "versions-lock.json") {
    Write-Host "   ✓ Файл versions-lock.json найден:" -ForegroundColor Green
    Get-Content "versions-lock.json" | ConvertFrom-Json | Format-List
} else {
    Write-Host "   ⚠ Файл versions-lock.json не найден" -ForegroundColor Yellow
}

# Проверка Docker контейнеров
Write-Host ""
Write-Host "5. Проверка Docker контейнеров..." -ForegroundColor Cyan
if (Get-Command docker -ErrorAction SilentlyContinue) {
    if (Test-Path "docker-compose.yml") {
        $containers = docker-compose ps 2>$null
        if ($containers) {
            Write-Host "   ✓ Контейнеры:" -ForegroundColor Green
            $containers
        } else {
            Write-Host "   ✗ Контейнеры не запущены" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ⚠ Docker не установлен" -ForegroundColor Yellow
}

# Проверка Kubernetes подов
Write-Host ""
Write-Host "6. Проверка Kubernetes подов..." -ForegroundColor Cyan
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    try {
        $namespace = kubectl get namespace element 2>$null
        if ($namespace) {
            Write-Host "   ✓ Namespace element существует:" -ForegroundColor Green
            kubectl get pods -n element
        } else {
            Write-Host "   ⚠ Namespace element не найден" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ⚠ Ошибка при проверке Kubernetes" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠ kubectl не установлен" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "Проверка завершена!" -ForegroundColor Green

