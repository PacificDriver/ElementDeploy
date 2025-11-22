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
            git pull origin master
        }
        Set-Location $REPOS_DIR
    } else {
        Write-Host "Клонируем $repo..." -ForegroundColor Cyan
        # Отключаем credential helper для клонирования публичных репозиториев без пароля
        $httpsUrl = "${ELEMENT_ORG}/${repo}.git"
        $sshUrl = "git@github.com:element-hq/${repo}.git"
        
        # Пробуем HTTPS с отключенным credential helper (без пароля для публичных репозиториев)
        try {
            $null = git -c credential.helper= clone $httpsUrl 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Успешно клонирован через HTTPS" -ForegroundColor Green
            } else {
                throw "HTTPS failed"
            }
        } catch {
            Write-Host "Пробуем SSH..." -ForegroundColor Yellow
            try {
                $null = git clone $sshUrl 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Успешно клонирован через SSH" -ForegroundColor Green
                } else {
                    throw "SSH failed"
                }
            } catch {
                Write-Host "❌ Ошибка: не удалось клонировать $repo" -ForegroundColor Red
                Write-Host "   Попробуйте очистить сохраненные credentials:" -ForegroundColor Yellow
                Write-Host "   git credential-manager-core erase" -ForegroundColor Yellow
                Write-Host "   (затем введите: https://github.com)" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "Все репозитории успешно клонированы в $REPOS_DIR" -ForegroundColor Green
Set-Location ..

