#!/bin/sh
# Скрипт автоматического развертывания Planka
# Строго совместим с POSIX sh (dash, ash, sh)

set -e # Останавливать выполнение при любой ошибке

echo "=========================================="
echo "Начало развертывания Planka"
echo "=========================================="

# -----------------------------------------------------------------------------
# 1. Проверка наличия необходимых утилит
# -----------------------------------------------------------------------------
echo "[1/7] Проверка зависимостей..."
command -v docker >/dev/null 2>&1 || { echo >&2 "ОШИБКА: docker не установлен."; exit 1; }
command -v git >/dev/null 2>&1 || { echo >&2 "ОШИБКА: git не установлен."; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo >&2 "ОШИБКА: openssl не установлен."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "ОШИБКА: curl не установлен."; exit 1; }
echo "Все зависимости найдены."

# -----------------------------------------------------------------------------
# 2. Генерация .env файла (Идемпотентно)
# -----------------------------------------------------------------------------
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    echo "[2/7] Генерация файла .env со случайными паролями..."

    SECRET_KEY=$(openssl rand -hex 32)
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    REDIS_PASSWORD=$(openssl rand -hex 16)

    cat <<EOF > "$ENV_FILE"
PLANKA_PORT=3000
BASE_URL=http://localhost:3000
SECRET_KEY=$SECRET_KEY
LOG_LEVEL=info
TRUST_PROXY=false

POSTGRES_IMAGE=postgres:16-alpine
POSTGRES_DB=planka
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_INITDB_ARGS=-c shared_buffers=256MB -c max_connections=200

REDIS_IMAGE=redis:7-alpine
REDIS_PASSWORD=$REDIS_PASSWORD

PLANKA_CPU_LIMIT=1
PLANKA_MEMORY_LIMIT=1G
PLANKA_CPU_RESERVATION=0.5
PLANKA_MEMORY_RESERVATION=512M
POSTGRES_CPU_LIMIT=0.5
POSTGRES_MEMORY_LIMIT=512M
POSTGRES_CPU_RESERVATION=0.25
POSTGRES_MEMORY_RESERVATION=256M
REDIS_CPU_LIMIT=0.25
REDIS_MEMORY_LIMIT=256M
REDIS_CPU_RESERVATION=0.1
REDIS_MEMORY_RESERVATION=128M
PLANKA_DATA_PATH=./data
DEFAULT_ADMIN_EMAIL=admin@example.com
DEFAULT_ADMIN_PASSWORD=admin-password-change-me
DEFAULT_ADMIN_NAME=Administrator
DEFAULT_ADMIN_USERNAME=admin
EOF
    echo "Файл .env успешно создан."
else
    echo "[2/7] Файл .env уже существует. Пропускаем генерацию (идемпотентность)."
fi

# -----------------------------------------------------------------------------
# 3. Сборка образов (если используется кастомный Dockerfile)
# -----------------------------------------------------------------------------
echo "[3/7] Сборка образов (docker compose build)..."
# Если в docker-compose.yml для planka указан 'build: .', это соберёт ваш Dockerfile.
# Если там только 'image:', эта команда просто проверит наличие образа.
docker compose build

# -----------------------------------------------------------------------------
# 4. Запуск СУБД и кэша (без planka, чтобы сначала сделать миграции)
# -----------------------------------------------------------------------------
echo "[4/7] Запуск Planka..."
docker compose up -d
sleep 30
# -----------------------------------------------------------------------------
# 5. Ожидание готовности СУБД
# -----------------------------------------------------------------------------
echo "[5/7] Ожидание готовности базы данных..."
MAX_RETRIES=30
RETRY_COUNT=0
HEALTH_STATUS="starting"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' planka-postgres 2>/dev/null || echo "not_found")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo "База данных успешно прошла проверку готовности!"
        break
    fi

    echo "  Ожидание... (попытка $((RETRY_COUNT + 1))/$MAX_RETRIES, статус: $HEALTH_STATUS)"
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ "$HEALTH_STATUS" != "healthy" ]; then
    echo "ОШИБКА: База данных не стала доступной за отведенное время."
    docker compose logs postgres
    exit 1
fi

# -----------------------------------------------------------------------------
# 6. Создание БД и выполнение миграций
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 7. Итоговый статус и проверка доступности
# -----------------------------------------------------------------------------
echo "[7/7] Финальная проверка доступности приложения..."

APP_PORT=$(grep '^PLANKA_PORT=' "$ENV_FILE" | cut -d '=' -f2-)
APP_PORT=${APP_PORT:-3000}

# Даём пару секунд на окончательную инициализацию
sleep 3

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$APP_PORT" || echo "000")

echo "=========================================="
echo "РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО!"
echo "=========================================="
echo "Адрес приложения: http://localhost:$APP_PORT"
echo "Тестовый пользователь: testuser"
echo "Статус проверки (HTTP): $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "Результат: УСПЕШНО. Приложение отвечает."
else
    echo "Результат: ВНИМАНИЕ. Неожиданный код ответа."
    echo "Рекомендуется проверить логи: docker compose logs planka"
fi
echo "=========================================="
