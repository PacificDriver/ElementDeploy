# PowerShell скрипт для клонирования репозиториев Element
# Использование: .\clone-repos.ps1

$ErrorActionPreference = "Stop"

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
        git clone "${ELEMENT_ORG}/${repo}.git"
    }
}

Write-Host "Все репозитории успешно клонированы в $REPOS_DIR" -ForegroundColor Green
Set-Location ..

