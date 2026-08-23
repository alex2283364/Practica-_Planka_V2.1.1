#!/bin/sh
# smoke_test.sh — проверка работоспособности приложения

set -e

echo "Запуск smoke-тестов..."

# Базовая проверка: главная страница
echo -n "Проверка GET / ... "
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$STATUS" = "200" ] || [ "$STATUS" = "302" ] || [ "$STATUS" = "401" ]; then
    echo "[OK] (HTTP $STATUS)"
else
    echo "[FAIL] (HTTP $STATUS)"
    exit 1
fi

# Проверка API (если есть)
echo -n "Проверка GET /api/health ... "
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health)
if [ "$STATUS" = "200" ]; then
    echo "[OK] (HTTP $STATUS)"
else
    echo "[FAIL] (HTTP $STATUS)"
    exit 1
fi

# Ещё одна проверка, например, /api/boards
echo -n "Проверка GET /api/boards ... "
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/boards)
if [ "$STATUS" = "200" ] || [ "$STATUS" = "401" ]; then
    echo "[OK] (HTTP $STATUS)"
else
    echo "[FAIL] (HTTP $STATUS)"
    exit 1
fi

echo "Все smoke-тесты пройдены успешно!"
exit 0
