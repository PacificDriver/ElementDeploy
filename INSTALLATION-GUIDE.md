# Полная инструкция по развертыванию Element на test.duxigo.org

## 📋 Предварительные требования

### Системные требования
- **ОС**: Linux (Ubuntu 20.04+ / Debian 11+ / CentOS 8+) или Windows Server
- **RAM**: минимум 2GB (рекомендуется 4GB+)
- **CPU**: минимум 2 ядра
- **Диск**: минимум 10GB свободного места

### Установленное ПО
- **Docker** версии 20.10+ и **Docker Compose** версии 2.0+
  ```bash
  # Ubuntu/Debian
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
  
  # Установка Docker Compose
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  ```

- **Git**
  ```bash
  sudo apt-get update
  sudo apt-get install git -y
  ```

- **Для Kubernetes (k3s)**:
  ```bash
  curl -sfL https://get.k3s.io | sh -
  ```

### DNS настройки
Убедитесь, что DNS записи настроены:
- `test.duxigo.org` → IP вашего сервера
- `call.test.duxigo.org` → IP вашего сервера (для Element Call)
- `synapse.test.duxigo.org` → IP вашего Synapse сервера (если используется отдельный сервер)

## 🚀 Пошаговая инструкция

### Шаг 1: Клонирование репозиториев Element

#### Windows (PowerShell)
```powershell
# Откройте PowerShell от имени администратора
.\clone-repos.ps1
```

#### Linux/Mac
```bash
chmod +x clone-repos.sh
./clone-repos.sh
```

Это создаст директорию `element-repos` со следующими репозиториями:
- `element-web` - Frontend веб-клиент
- `element-call` - Backend для RTC/видео звонков
- `matrix-js-sdk` - JavaScript SDK
- `matrix-react-sdk` - React SDK
- `matrix-widget-api` - Widget API

**Время выполнения**: 5-10 минут (зависит от скорости интернета)

---

### Шаг 2: Настройка переменных окружения

1. **Создайте файл `.env`**:
   ```bash
   # Linux/Mac
   cp env.example .env
   
   # Windows
   Copy-Item env.example .env
   ```

2. **Откройте `.env` и настройте следующие параметры**:

   ```env
   # ⚠️ ОБЯЗАТЕЛЬНО: Укажите URL вашего существующего Synapse сервера
   SYNAPSE_BASE_URL=https://synapse.test.duxigo.org
   SYNAPSE_SERVER_NAME=test.duxigo.org
   SYNAPSE_HOST=synapse.test.duxigo.org
   
   # Element Web
   ELEMENT_WEB_DOMAIN=test.duxigo.org
   ELEMENT_WEB_URL=https://test.duxigo.org
   
   # Element Call
   ELEMENT_CALL_BASE_URL=https://call.test.duxigo.org
   ELEMENT_CALL_SERVER_NAME=element-call
   ELEMENT_CALL_URL=https://call.test.duxigo.org
   
   # Identity Server (опционально, можно оставить по умолчанию)
   IDENTITY_SERVER_URL=https://vector.im
   
   # Версии SDK (рекомендуется зафиксировать)
   MATRIX_JS_SDK_VERSION=30.0.0
   MATRIX_REACT_SDK_VERSION=3.90.0
   ELEMENT_WEB_VERSION=1.11.0
   ELEMENT_CALL_VERSION=0.5.0
   
   # RTC конфигурация (для голосовых/видео звонков)
   # Если у вас есть TURN сервер, укажите его данные
   TURN_SERVER_URL=turn:turn.test.duxigo.org:3478
   TURN_USERNAME=your_turn_username
   TURN_PASSWORD=your_turn_password
   STUN_SERVER_URL=stun:stun.test.duxigo.org:3478
   ```

   **Важно**: 
   - Замените `synapse.test.duxigo.org` на реальный URL вашего Synapse сервера
   - Если Synapse на другом домене, укажите полный URL (например, `https://matrix.example.com`)

---

### Шаг 3: Фиксация версий SDK

Этот шаг гарантирует стабильность и совместимость компонентов.

#### Windows
```powershell
.\fix-sdk-versions.ps1
```

#### Linux/Mac
```bash
chmod +x fix-sdk-versions.sh
./fix-sdk-versions.sh
```

Скрипт:
- Переключит все репозитории на указанные версии
- Создаст файл `versions-lock.json` с информацией о зафиксированных версиях

**Время выполнения**: 2-5 минут

---

### Шаг 4: Настройка SSL сертификатов

#### Вариант A: Let's Encrypt (рекомендуется)

```bash
# Установка certbot
sudo apt-get update
sudo apt-get install certbot -y

# Получение сертификатов
sudo certbot certonly --standalone -d test.duxigo.org -d call.test.duxigo.org

# Сертификаты будут в:
# /etc/letsencrypt/live/test.duxigo.org/fullchain.pem
# /etc/letsencrypt/live/test.duxigo.org/privkey.pem
```

#### Вариант B: Использование существующих сертификатов

Скопируйте ваши сертификаты в директорию `certs/`:
```bash
mkdir -p certs
cp your-fullchain.pem certs/fullchain.pem
cp your-privkey.pem certs/privkey.pem
chmod 600 certs/privkey.pem
```

---

### Шаг 5: Деплой

Выберите один из вариантов:

#### Вариант A: Docker Compose (проще для начала)

##### Windows
```powershell
.\deploy.ps1 docker
```

##### Linux/Mac
```bash
chmod +x deploy.sh
./deploy.sh docker
```

**Что происходит**:
1. Создаются необходимые директории
2. Загружаются Docker образы
3. Запускаются контейнеры:
   - `element-web` на порту 8080
   - `element-call` на портах 3000 и 8443
   - `nginx` на портах 80 и 443 (если используется)

**Проверка статуса**:
```bash
docker-compose ps
docker-compose logs -f
```

#### Вариант B: Kubernetes (k3s) - для production

##### Применение манифестов
```bash
# Создание namespace
kubectl apply -f k8s/namespace.yaml

# Применение конфигураций
kubectl apply -f k8s/configmap-element-web.yaml
kubectl apply -f k8s/configmap-element-call.yaml

# Деплой сервисов
kubectl apply -f k8s/element-web-deployment.yaml
kubectl apply -f k8s/element-call-deployment.yaml

# Настройка Ingress
kubectl apply -f k8s/ingress.yaml
```

##### Или используйте скрипт:
```bash
./deploy.sh k8s
```

**Проверка статуса**:
```bash
kubectl get pods -n element
kubectl get svc -n element
kubectl get ingress -n element
```

---

### Шаг 6: Настройка Nginx (если используется отдельный Nginx)

Если у вас уже есть Nginx на сервере, добавьте конфигурацию:

```nginx
# /etc/nginx/sites-available/test.duxigo.org
server {
    listen 80;
    server_name test.duxigo.org;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name test.duxigo.org;

    ssl_certificate /etc/letsencrypt/live/test.duxigo.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/test.duxigo.org/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name call.test.duxigo.org;

    ssl_certificate /etc/letsencrypt/live/test.duxigo.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/test.duxigo.org/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket для RTC
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Активируйте конфигурацию:
```bash
sudo ln -s /etc/nginx/sites-available/test.duxigo.org /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

### Шаг 7: Проверка взаимодействия

Запустите скрипт проверки:

#### Windows
```powershell
.\test-connection.ps1
```

#### Linux/Mac
```bash
chmod +x test-connection.sh
./test-connection.sh
```

Скрипт проверит:
- ✅ Доступность Synapse сервера
- ✅ Доступность Element Web
- ✅ Доступность Element Call
- ✅ Версии SDK
- ✅ Статус контейнеров/подов

---

### Шаг 8: Настройка Synapse (если нужно)

Убедитесь, что ваш Synapse сервер настроен правильно:

1. **Включите CORS** (если Element на другом домене):
   ```yaml
   # homeserver.yaml
   cors:
     allowed_origins:
       - "https://test.duxigo.org"
       - "https://call.test.duxigo.org"
   ```

2. **Настройте интеграции** (scalar):
   ```yaml
   integrations:
     ui_url: "https://scalar.vector.im/"
     rest_url: "https://scalar.vector.im/api"
   ```

3. **Включите E2E шифрование**:
   ```yaml
   encryption_enabled_by_default_for_room_type: "all"
   ```

4. **Перезапустите Synapse**:
   ```bash
   sudo systemctl restart synapse
   ```

---

## 🔧 Настройка RTC (голосовые/видео звонки)

### Настройка TURN сервера

Element Call требует TURN сервер для работы через NAT. Варианты:

#### Вариант 1: Использовать существующий TURN сервер

Обновите `.env`:
```env
TURN_SERVER_URL=turn:turn.test.duxigo.org:3478
TURN_USERNAME=your_username
TURN_PASSWORD=your_password
STUN_SERVER_URL=stun:stun.test.duxigo.org:3478
```

#### Вариант 2: Развернуть coturn

```bash
# Установка coturn
sudo apt-get install coturn -y

# Настройка /etc/turnserver.conf
listening-port=3478
tls-listening-port=5349
listening-ip=0.0.0.0
external-ip=YOUR_SERVER_IP
realm=test.duxigo.org
server-name=test.duxigo.org
lt-cred-mech
user=element:password
cert=/etc/letsencrypt/live/test.duxigo.org/fullchain.pem
pkey=/etc/letsencrypt/live/test.duxigo.org/privkey.pem

# Запуск
sudo systemctl enable coturn
sudo systemctl start coturn
```

---

## 📊 Мониторинг и логи

### Docker Compose
```bash
# Просмотр логов
docker-compose logs -f element-web
docker-compose logs -f element-call

# Статус контейнеров
docker-compose ps

# Перезапуск сервиса
docker-compose restart element-web
```

### Kubernetes
```bash
# Логи подов
kubectl logs -f deployment/element-web -n element
kubectl logs -f deployment/element-call -n element

# Статус
kubectl get pods -n element -w
kubectl describe pod <pod-name> -n element
```

---

## 🔄 Обновление

### Обновление версий

1. Обновите версии в `.env`
2. Запустите `fix-sdk-versions.sh`
3. Перезапустите деплой:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

### Обновление конфигурации

После изменения `.env`:
```bash
docker-compose down
docker-compose up -d
```

---

## 🐛 Troubleshooting

### Element Web не подключается к Synapse

1. **Проверьте URL Synapse**:
   ```bash
   curl https://synapse.test.duxigo.org/_matrix/client/versions
   ```

2. **Проверьте CORS настройки** в Synapse

3. **Проверьте логи**:
   ```bash
   docker-compose logs element-web
   ```

4. **Проверьте конфигурацию**:
   ```bash
   cat config/element-web-config.json
   ```

### Element Call не работает

1. **Проверьте доступность**:
   ```bash
   curl http://localhost:3000/health
   ```

2. **Проверьте WebSocket**:
   - Откройте DevTools в браузере
   - Проверьте Network → WS соединения

3. **Проверьте TURN сервер**:
   ```bash
   turnutils_stunclient turn.test.duxigo.org
   ```

### Проблемы с SSL

1. **Проверьте сертификаты**:
   ```bash
   openssl s_client -connect test.duxigo.org:443 -servername test.duxigo.org
   ```

2. **Обновите сертификаты Let's Encrypt**:
   ```bash
   sudo certbot renew
   ```

---

## ✅ Чек-лист после установки

- [ ] DNS записи настроены и резолвятся
- [ ] SSL сертификаты установлены и валидны
- [ ] Element Web доступен по https://test.duxigo.org
- [ ] Element Call доступен по https://call.test.duxigo.org
- [ ] Подключение к Synapse работает
- [ ] Можно войти в аккаунт
- [ ] Голосовые/видео звонки работают
- [ ] Логи не показывают критических ошибок

---

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи: `docker-compose logs` или `kubectl logs`
2. Запустите `test-connection.sh` для диагностики
3. Проверьте документацию: https://element.io/docs

---

## 🎉 Готово!

После выполнения всех шагов Element Web будет доступен по адресу:
**https://test.duxigo.org**

Element Call для звонков:
**https://call.test.duxigo.org**

