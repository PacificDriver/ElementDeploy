# Быстрый старт - Element Deployment

## Шаг 1: Клонирование репозиториев

### Windows (PowerShell)
```powershell
.\clone-repos.ps1
```

### Linux/Mac (Bash)
```bash
chmod +x clone-repos.sh
./clone-repos.sh
```

## Шаг 2: Настройка конфигурации

1. Скопируйте файл примера:
   ```bash
   # Windows
   Copy-Item env.example .env
   
   # Linux/Mac
   cp env.example .env
   ```

2. Откройте `.env` и укажите:
   - `SYNAPSE_BASE_URL` - URL вашего Synapse сервера
   - `SYNAPSE_SERVER_NAME` - Имя вашего сервера
   - Остальные параметры по необходимости

## Шаг 3: Фиксация версий SDK

### Windows
```powershell
.\fix-sdk-versions.ps1
```

### Linux/Mac
```bash
chmod +x fix-sdk-versions.sh
./fix-sdk-versions.sh
```

## Шаг 4: Деплой

### Вариант A: Docker Compose

**Windows:**
```powershell
.\deploy.ps1 docker
```

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh docker
```

После деплоя:
- Element Web: http://localhost:8080
- Element Call: http://localhost:3000

### Вариант B: Kubernetes (k3s)

**Windows:**
```powershell
.\deploy.ps1 k8s
```

**Linux/Mac:**
```bash
./deploy.sh k8s
```

## Шаг 5: Проверка

### Windows
```powershell
.\test-connection.ps1
```

### Linux/Mac
```bash
chmod +x test-connection.sh
./test-connection.sh
```

## Что дальше?

1. Откройте Element Web в браузере
2. Войдите с учетными данными вашего Synapse сервера
3. Проверьте работу голосовых/видео звонков через Element Call

## Troubleshooting

### Проблемы с подключением к Synapse

1. Проверьте, что `SYNAPSE_BASE_URL` правильный
2. Убедитесь, что Synapse доступен из сети контейнеров/подов
3. Проверьте логи: `docker-compose logs` или `kubectl logs -n element`

### Проблемы с RTC/звонками

1. Настройте TURN/STUN серверы в `.env`
2. Проверьте, что порты открыты
3. Убедитесь, что WebSocket соединения работают

