# Element Web Deployment

Полный набор скриптов и конфигураций для развертывания Element Web и Element Call с подключением к существующему Synapse серверу.

## Структура проекта

```
.
├── clone-repos.sh / .ps1          # Скрипты клонирования репозиториев
├── deploy.sh / .ps1                # Скрипты деплоя
├── fix-sdk-versions.sh / .ps1      # Фиксация версий SDK
├── test-connection.sh / .ps1       # Проверка взаимодействия
├── docker-compose.yml              # Docker Compose конфигурация
├── .env.example                    # Пример файла переменных окружения
├── config/                         # Конфигурационные файлы
│   ├── element-web-config.json
│   └── element-call-config.json
├── k8s/                            # Kubernetes манифесты
│   ├── namespace.yaml
│   ├── element-web-deployment.yaml
│   ├── element-call-deployment.yaml
│   ├── configmap-element-web.yaml
│   ├── configmap-element-call.yaml
│   └── ingress.yaml
└── nginx/                          # Nginx конфигурация
    ├── nginx.conf
    └── conf.d/
        └── element.conf
```

## Быстрый старт

### 1. Клонирование репозиториев

**Linux/Mac:**
```bash
chmod +x clone-repos.sh
./clone-repos.sh
```

**Windows:**
```powershell
.\clone-repos.ps1
```

### 2. Настройка переменных окружения

Скопируйте `env.example` в `.env` и заполните значения:

```bash
cp env.example .env
# Отредактируйте .env файл
```

**Windows:**
```powershell
Copy-Item env.example .env
# Отредактируйте .env файл
```

Обязательные переменные:
- `SYNAPSE_BASE_URL` - URL вашего Synapse сервера
- `SYNAPSE_SERVER_NAME` - Имя вашего сервера

### 3. Фиксация версий SDK

**Linux/Mac:**
```bash
chmod +x fix-sdk-versions.sh
./fix-sdk-versions.sh
```

**Windows:**
```powershell
.\fix-sdk-versions.ps1
```

### 4. Деплой

#### Docker Compose

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh docker
```

**Windows:**
```powershell
.\deploy.ps1 docker
```

#### Kubernetes (k3s)

**Linux/Mac:**
```bash
./deploy.sh k8s
```

**Windows:**
```powershell
.\deploy.ps1 k8s
```

### 5. Проверка взаимодействия

**Linux/Mac:**
```bash
chmod +x test-connection.sh
./test-connection.sh
```

**Windows:**
```powershell
.\test-connection.ps1
```

## Конфигурация

### Подключение к существующему Synapse

1. Убедитесь, что ваш Synapse сервер доступен и работает
2. В файле `.env` укажите правильный `SYNAPSE_BASE_URL`
3. Проверьте, что Synapse настроен для работы с Element:
   - Включено E2E шифрование
   - Настроены интеграции (scalar)
   - Доступны необходимые API endpoints

### RTC конфигурация

Для работы голосовых и видеозвонков настройте TURN/STUN серверы в `.env`:

```env
TURN_SERVER_URL=turn:turn.example.com:3478
TURN_USERNAME=your_username
TURN_PASSWORD=your_password
STUN_SERVER_URL=stun:stun.example.com:3478
```

### Фиксация версий

Версии SDK фиксируются в файле `.env`:

```env
MATRIX_JS_SDK_VERSION=30.0.0
MATRIX_REACT_SDK_VERSION=3.90.0
ELEMENT_WEB_VERSION=1.11.0
ELEMENT_CALL_VERSION=0.5.0
```

После изменения версий запустите `fix-sdk-versions.sh` для применения изменений.

## Проверка взаимодействия с Element X

Скрипт `test-connection.sh` проверяет:

1. Доступность Synapse сервера
2. Доступность Element Web
3. Доступность Element Call
4. Версии SDK
5. RTC конфигурацию
6. Статус контейнеров/подов

## Troubleshooting

### Element Web не подключается к Synapse

1. Проверьте `SYNAPSE_BASE_URL` в `.env`
2. Убедитесь, что Synapse доступен из контейнера/пода
3. Проверьте CORS настройки на Synapse
4. Проверьте логи: `docker-compose logs element-web`

### Element Call не работает

1. Проверьте настройки TURN/STUN серверов
2. Убедитесь, что порты 3000 и 8443 открыты
3. Проверьте WebSocket соединения
4. Проверьте логи: `docker-compose logs element-call`

### Проблемы с версиями SDK

1. Убедитесь, что версии совместимы
2. Проверьте `versions-lock.json`
3. Перезапустите `fix-sdk-versions.sh`

## Дополнительные ресурсы

- [Element Web Documentation](https://element.io/docs)
- [Matrix Synapse Documentation](https://matrix-org.github.io/synapse/)
- [Element Call Documentation](https://github.com/element-hq/element-call)

## Лицензия

Этот проект содержит скрипты и конфигурации для развертывания Element. Сами проекты Element распространяются под соответствующими лицензиями.

