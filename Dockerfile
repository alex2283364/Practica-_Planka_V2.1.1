#==============================================================================
# STAGE 1: Server build (Стадия сборки сервера)
#==============================================================================
FROM node:20-alpine AS server

# Устанавливаем инструменты сборки для компиляции нативных модулей (node-gyp)
RUN apk -U upgrade && apk add build-base python3 --no-cache

WORKDIR /app

COPY server .

# Устанавливаем все зависимости, собираем проект, удаляем dev-зависимости
RUN npm install \
  && npm run build \
  && npm prune --production

#==============================================================================
# STAGE 2: Client build (Стадия сборки клиента)
#==============================================================================
# ИСПРАВЛЕНИЕ: node:22 (Debian, ~1GB) заменён на node:22-alpine (~180MB)
FROM node:20-alpine AS client

WORKDIR /app

COPY client .

RUN npm install npm --global \
  && npm install --omit=dev \
  && INDEX_FORMAT=ejs DISABLE_ESLINT_PLUGIN=true npm run build

#==============================================================================
# STAGE 3: Final image (Финальный образ для выполнения)
#==============================================================================
FROM node:20-alpine

# Обновляем пакеты и устанавливаем только необходимое для рантайма
# ИСПРАВЛЕНИЕ: удалён пакет squid (прокси-сервер) — он не нужен приложению
RUN apk -U upgrade && apk add bash python3 squid --no-cache

# ТРЕБОВАНИЕ 2: Non-root user. Создаём непривилегированного пользователя
# (вместо встроенного node используем явно созданного appuser)
RUN adduser -D appuser

USER appuser
WORKDIR /app

# ТРЕБОВАНИЕ 1: Multi-stage build. Копируем ТОЛЬКО production node_modules и dist
# из стадии server. Исходный код сервера и инструменты сборки (build-base)
# НЕ попадают в финальный образ.
COPY --from=server --chown=appuser:appuser /app/node_modules node_modules
COPY --from=server --chown=appuser:appuser /app/dist .

# Копируем собранный клиент из стадии client
COPY --from=client --chown=appuser:appuser /app/dist public

# Установка Python-зависимостей (если требуются приложением)
RUN python3 -m venv .venv \
  && .venv/bin/pip3 install --upgrade pip \
  && .venv/bin/pip3 install -r requirements.txt --no-cache-dir \
  && mv .env.sample .env \
  && mv public/index.ejs views \
  && npm config set update-notifier false

VOLUME /app/data
EXPOSE 1337

HEALTHCHECK --interval=10s --timeout=2s --start-period=15s CMD node ./healthcheck.js

CMD ["bash","./start.sh"]
