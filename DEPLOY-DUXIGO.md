# 🚀 Быстрый деплой Element на test.duxigo.org

## Автоматическая установка (рекомендуется)

### Linux/Mac
```bash
chmod +x setup-duxigo.sh
./setup-duxigo.sh
```

### Windows
```powershell
.\setup-duxigo.ps1
```

## Ручная установка

### 1. Подготовка окружения

```bash
# Создайте .env файл
cp env.example .env

# Отредактируйте .env и укажите:
# - SYNAPSE_BASE_URL=https://synapse.test.duxigo.org (или ваш реальный URL)
# - Остальные параметры по необходимости
```

### 2. Клонирование репозиториев

```bash
# Linux/Mac
./clone-repos.sh

# Windows
.\clone-repos.ps1
```

### 3. Фиксация версий SDK

```bash
# Linux/Mac
./fix-sdk-versions.sh

# Windows
.\fix-sdk-versions.ps1
```

### 4. Настройка SSL

```bash
# Получение сертификатов Let's Encrypt
sudo certbot certonly --standalone -d test.duxigo.org -d call.test.duxigo.org

# Копирование сертификатов
sudo cp /etc/letsencrypt/live/test.duxigo.org/fullchain.pem certs/
sudo cp /etc/letsencrypt/live/test.duxigo.org/privkey.pem certs/
sudo chmod 600 certs/privkey.pem
```

### 5. Деплой

```bash
# Docker Compose
./deploy.sh docker
# или
docker-compose up -d

# Kubernetes
./deploy.sh k8s
```

### 6. Проверка

```bash
# Проверка статуса
docker-compose ps
# или
kubectl get pods -n element

# Тест подключения
./test-connection.sh
```

## Доступ

После успешного деплоя:

- **Element Web**: https://test.duxigo.org
- **Element Call**: https://call.test.duxigo.org

## Важные настройки

### В файле .env обязательно укажите:

```env
SYNAPSE_BASE_URL=https://ваш-реальный-synapse-сервер
SYNAPSE_SERVER_NAME=test.duxigo.org
```

### Если Synapse на другом домене:

```env
SYNAPSE_BASE_URL=https://matrix.example.com
SYNAPSE_SERVER_NAME=example.com
```

## Troubleshooting

### Проверка DNS
```bash
nslookup test.duxigo.org
nslookup call.test.duxigo.org
```

### Проверка портов
```bash
netstat -tuln | grep -E '80|443|8080|3000'
```

### Логи
```bash
docker-compose logs -f
```

## Полная документация

См. [INSTALLATION-GUIDE.md](INSTALLATION-GUIDE.md) для детальной инструкции.

