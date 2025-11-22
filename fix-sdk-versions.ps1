# PowerShell скрипт для фиксации версий SDK и RTC конфигурации
# Использование: .\fix-sdk-versions.ps1

$ErrorActionPreference = "Stop"

$REPOS_DIR = ".\element-repos"
$ENV_FILE = ".env"

# Загружаем версии из .env
if (Test-Path $ENV_FILE) {
    Get-Content $ENV_FILE | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Variable -Name $name -Value $value -Scope Script
        }
    }
}

# Версии по умолчанию
$MATRIX_JS_SDK_VERSION = if ($MATRIX_JS_SDK_VERSION) { $MATRIX_JS_SDK_VERSION } else { "30.0.0" }
$MATRIX_REACT_SDK_VERSION = if ($MATRIX_REACT_SDK_VERSION) { $MATRIX_REACT_SDK_VERSION } else { "3.90.0" }
$ELEMENT_WEB_VERSION = if ($ELEMENT_WEB_VERSION) { $ELEMENT_WEB_VERSION } else { "1.11.0" }
$ELEMENT_CALL_VERSION = if ($ELEMENT_CALL_VERSION) { $ELEMENT_CALL_VERSION } else { "0.5.0" }

Write-Host "Фиксация версий SDK и RTC конфигурации..." -ForegroundColor Green
Write-Host "Matrix JS SDK: $MATRIX_JS_SDK_VERSION" -ForegroundColor Cyan
Write-Host "Matrix React SDK: $MATRIX_REACT_SDK_VERSION" -ForegroundColor Cyan
Write-Host "Element Web: $ELEMENT_WEB_VERSION" -ForegroundColor Cyan
Write-Host "Element Call: $ELEMENT_CALL_VERSION" -ForegroundColor Cyan

if (-not (Test-Path $REPOS_DIR)) {
    Write-Host "Директория $REPOS_DIR не найдена. Запустите сначала clone-repos.ps1" -ForegroundColor Red
    exit 1
}

Set-Location $REPOS_DIR

# Фиксируем версии в element-web
if (Test-Path "element-web") {
    Write-Host "Обновление версий в element-web..." -ForegroundColor Yellow
    Set-Location element-web
    git fetch --tags
    $tag = "v$ELEMENT_WEB_VERSION"
    git checkout $tag 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout $ELEMENT_WEB_VERSION
    }
    Set-Location ..
}

# Фиксируем версии в matrix-js-sdk
if (Test-Path "matrix-js-sdk") {
    Write-Host "Обновление версий в matrix-js-sdk..." -ForegroundColor Yellow
    Set-Location matrix-js-sdk
    git fetch --tags
    $tag = "v$MATRIX_JS_SDK_VERSION"
    git checkout $tag 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout $MATRIX_JS_SDK_VERSION
    }
    Set-Location ..
}

# Фиксируем версии в matrix-react-sdk
if (Test-Path "matrix-react-sdk") {
    Write-Host "Обновление версий в matrix-react-sdk..." -ForegroundColor Yellow
    Set-Location matrix-react-sdk
    git fetch --tags
    $tag = "v$MATRIX_REACT_SDK_VERSION"
    git checkout $tag 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout $MATRIX_REACT_SDK_VERSION
    }
    Set-Location ..
}

# Фиксируем версии в element-call
if (Test-Path "element-call") {
    Write-Host "Обновление версий в element-call..." -ForegroundColor Yellow
    Set-Location element-call
    git fetch --tags
    $tag = "v$ELEMENT_CALL_VERSION"
    git checkout $tag 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout $ELEMENT_CALL_VERSION
    }
    Set-Location ..
}

Set-Location ..

Write-Host "Версии SDK зафиксированы!" -ForegroundColor Green
Write-Host "Создаем файл с информацией о версиях..." -ForegroundColor Yellow

# Создаем файл с информацией о версиях
$versions = @{
    locked_versions = @{
        "matrix-js-sdk" = $MATRIX_JS_SDK_VERSION
        "matrix-react-sdk" = $MATRIX_REACT_SDK_VERSION
        "element-web" = $ELEMENT_WEB_VERSION
        "element-call" = $ELEMENT_CALL_VERSION
        "lock_date" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
    rtc_config = @{
        "turn_server" = if ($TURN_SERVER_URL) { $TURN_SERVER_URL } else { "not_configured" }
        "stun_server" = if ($STUN_SERVER_URL) { $STUN_SERVER_URL } else { "not_configured" }
    }
}

$versions | ConvertTo-Json -Depth 10 | Out-File -FilePath "versions-lock.json" -Encoding UTF8

Write-Host "Информация о версиях сохранена в versions-lock.json" -ForegroundColor Green

