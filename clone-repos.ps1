# PowerShell скрипт для клонирования репозиториев Element
# Использование: .\clone-repos.ps1

# Не останавливаем скрипт при ошибках, чтобы обрабатывать ошибки клонирования вручную
$ErrorActionPreference = "Continue"

$ELEMENT_ORG = "https://github.com/element-hq"
$REPOS_DIR = ".\element-repos"

# Создаем директорию для репозиториев
if (-not (Test-Path $REPOS_DIR)) {
    New-Item -ItemType Directory -Path $REPOS_DIR | Out-Null
}
Set-Location $REPOS_DIR

Write-Host "Клонирование репозиториев Element..." -ForegroundColor Green

# Основные репозитории для веб-клиента
$REPOS = @(
    "element-web",           # Frontend веб-клиент
    "element-call",          # Backend для RTC/видео звонков
    "matrix-js-sdk",         # JavaScript SDK
    "matrix-react-sdk",      # React SDK
    "matrix-widget-api"      # Widget API
)

# Клонируем каждый репозиторий
foreach ($repo in $REPOS) {
    $repoPath = Join-Path $REPOS_DIR $repo
    if (Test-Path $repoPath) {
        Write-Host "Репозиторий $repo уже существует, обновляем..." -ForegroundColor Yellow
        Set-Location $repoPath
        git pull origin main 2>$null
        if ($LASTEXITCODE -ne 0) {
            git pull origin master 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "⚠️  Не удалось обновить $repo" -ForegroundColor Yellow
            }
        }
        Set-Location $REPOS_DIR
    } else {
        Write-Host "Клонируем $repo..." -ForegroundColor Cyan
        
        # Используем только HTTPS для публичных репозиториев
        $httpsUrl = "${ELEMENT_ORG}/${repo}.git"
        
        # Пробуем клонировать с отключенным credential helper
        $env:GIT_TERMINAL_PROMPT = "0"
        $env:GIT_ASKPASS = "echo"
        
        $cloneSuccess = $false
        
        # Пробуем без credential helper
        try {
            $null = git -c credential.helper= clone --depth=1 $httpsUrl 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $repo успешно клонирован через HTTPS" -ForegroundColor Green
                $cloneSuccess = $true
            }
        } catch {
            # Игнорируем ошибку, пробуем следующий способ
        }
        
        # Если не получилось, пробуем обычный способ
        if (-not $cloneSuccess) {
            try {
                $null = git clone --depth=1 $httpsUrl 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ $repo успешно клонирован через HTTPS (с credentials)" -ForegroundColor Green
                    $cloneSuccess = $true
                }
            } catch {
                # Игнорируем ошибку
            }
        }
        
        # Если всё ещё не получилось
        if (-not $cloneSuccess) {
            Write-Host "❌ Ошибка: не удалось клонировать $repo" -ForegroundColor Red
            Write-Host ""
            Write-Host "Возможные решения:" -ForegroundColor Yellow
            Write-Host "1. Очистите сохраненные credentials:" -ForegroundColor Yellow
            Write-Host "   git credential-manager-core erase" -ForegroundColor Cyan
            Write-Host "   (затем введите: https://github.com)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "2. Или клонируйте вручную:" -ForegroundColor Yellow
            Write-Host "   cd $REPOS_DIR" -ForegroundColor Cyan
            Write-Host "   git clone --depth=1 $httpsUrl" -ForegroundColor Cyan
            Write-Host ""
            
            $continue = Read-Host "Продолжить с остальными репозиториями? (y/n)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                Write-Host "Прервано пользователем" -ForegroundColor Red
                Set-Location ..
                exit 1
            }
        }
    }
}

Write-Host "Все репозитории успешно клонированы в $REPOS_DIR" -ForegroundColor Green
Set-Location ..

