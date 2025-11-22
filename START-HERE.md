# 🎯 Начните здесь - Деплой Element на test.duxigo.org

## 📌 Краткая инструкция

### Вариант 1: Автоматическая установка (рекомендуется)

#### Windows
```powershell
.\setup-duxigo.ps1
.\deploy.ps1 docker
```

#### Linux/Mac
```bash
chmod +x setup-duxigo.sh
./setup-duxigo.sh
./deploy.sh docker
```

### Вариант 2: Ручная установка

1. **Создайте `.env` файл**:
   ```bash
   cp env.example .env
   # Отредактируйте .env и укажите реальный URL вашего Synapse
   ```

2. **Клонируйте репозитории**:
   ```bash
   ./clone-repos.sh  # или .\clone-repos.ps1
   ```

3. **Зафиксируйте версии SDK**:
   ```bash
   ./fix-sdk-versions.sh  # или .\fix-sdk-versions.ps1
   ```

4. **Настройте SSL** (если нужно):
   ```bash
   sudo certbot certonly --standalone -d test.duxigo.org -d call.test.duxigo.org
   sudo cp /etc/letsencrypt/live/test.duxigo.org/*.pem certs/
   ```

5. **Запустите деплой**:
   ```bash
   ./deploy.sh docker  # или .\deploy.ps1 docker
   ```

6. **Проверьте**:
   ```bash
   ./test-connection.sh  # или .\test-connection.ps1
   ```

## 🌐 Доступ после установки

- **Element Web**: https://test.duxigo.org
- **Element Call**: https://call.test.duxigo.org

## ⚠️ Важно!

**Перед деплоем обязательно укажите в `.env` файле:**

```env
SYNAPSE_BASE_URL=https://ваш-реальный-synapse-сервер
```

Если ваш Synapse на другом домене (не synapse.test.duxigo.org), укажите полный URL.

## 📚 Документация

- **Полная инструкция**: [INSTALLATION-GUIDE.md](INSTALLATION-GUIDE.md)
- **Быстрый деплой**: [DEPLOY-DUXIGO.md](DEPLOY-DUXIGO.md)
- **Общая документация**: [README.md](README.md)

## 🆘 Проблемы?

1. Проверьте логи: `docker-compose logs`
2. Запустите тест: `./test-connection.sh`
3. См. раздел Troubleshooting в [INSTALLATION-GUIDE.md](INSTALLATION-GUIDE.md)

