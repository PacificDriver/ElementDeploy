# PowerShell скрипт деплоя Element Web и Element Call
# Использование: .\deploy.ps1 [docker|k8s] [env-file]

param(
    [Parameter(Position=0)]
    [ValidateSet("docker", "k8s")]
    [string]$DeployType = "docker",
    
    [Parameter(Position=1)]
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

# Загружаем переменные окружения
if (Test-Path $EnvFile) {
    Write-Host "Загрузка переменных окружения из $EnvFile..." -ForegroundColor Green
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Проверяем обязательные переменные
if (-not $env:SYNAPSE_BASE_URL) {
    Write-Host "ОШИБКА: SYNAPSE_BASE_URL не установлен" -ForegroundColor Red
    Write-Host "Создайте файл .env с необходимыми переменными" -ForegroundColor Yellow
    exit 1
}

Write-Host "Тип деплоя: $DeployType" -ForegroundColor Cyan
Write-Host "Synapse URL: $env:SYNAPSE_BASE_URL" -ForegroundColor Cyan

switch ($DeployType) {
    "docker" {
        Write-Host "Деплой через Docker Compose..." -ForegroundColor Green
        
        # Создаем директории
        @("config", "certs", "nginx\conf.d", "builds") | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ | Out-Null
            }
        }
        
        # Запускаем Docker Compose
        docker-compose down
        docker-compose pull
        docker-compose up -d
        
        Write-Host "Проверка статуса контейнеров..." -ForegroundColor Yellow
        docker-compose ps
        
        Write-Host "Деплой завершен!" -ForegroundColor Green
        Write-Host "Element Web доступен на: http://localhost:8080" -ForegroundColor Cyan
        Write-Host "Element Call доступен на: http://localhost:3000" -ForegroundColor Cyan
    }
    
    "k8s" {
        Write-Host "Деплой через Kubernetes (k3s)..." -ForegroundColor Green
        
        # Применяем манифесты
        kubectl apply -f k8s/namespace.yaml
        kubectl apply -f k8s/configmap-element-web.yaml
        kubectl apply -f k8s/configmap-element-call.yaml
        kubectl apply -f k8s/element-web-deployment.yaml
        kubectl apply -f k8s/element-call-deployment.yaml
        kubectl apply -f k8s/ingress.yaml
        
        Write-Host "Ожидание готовности подов..." -ForegroundColor Yellow
        kubectl wait --for=condition=ready pod -l app=element-web -n element --timeout=300s
        kubectl wait --for=condition=ready pod -l app=element-call -n element --timeout=300s
        
        Write-Host "Статус подов:" -ForegroundColor Yellow
        kubectl get pods -n element
        
        Write-Host "Деплой завершен!" -ForegroundColor Green
    }
}

