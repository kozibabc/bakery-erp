#!/bin/bash

###############################################################################
# Bakery ERP - Полная установка
###############################################################################

set -e

echo "🍰 Bakery ERP - Автоматическое создание всех файлов"
echo "===================================================="
echo ""

if [ ! -d ".git" ]; then
    echo "❌ Запустите скрипт в корне git репозитория!"
    echo "git clone git@github.com:kozibabc/bakery-erp.git && cd bakery-erp"
    exit 1
fi

echo "✅ Git репозиторий найден"
echo ""

mkdir -p backend/src/{config,routes,controllers,services,middleware,models}
mkdir -p frontend/src/{components,pages,services,utils}
mkdir -p frontend/public
mkdir -p nginx/conf.d
mkdir -p database/init
mkdir -p logs/{backend,nginx}
echo "✅ Директории созданы"
echo ""

### КОРНЕВЫЕ ФАЙЛЫ

cat > docker-compose.yml << 'EOFCOMPOSE'
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    container_name: bakery-erp-db
    environment:
      POSTGRES_DB: bakery_erp
      POSTGRES_USER: bakery_user
      POSTGRES_PASSWORD: ${DB_PASSWORD:-bakery_pass_2024}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=ru_RU.UTF-8"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - bakery-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U bakery_user -d bakery_erp"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: bakery-erp-backend
    environment:
      NODE_ENV: production
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: bakery_erp
      DB_USER: bakery_user
      DB_PASSWORD: ${DB_PASSWORD:-bakery_pass_2024}
      JWT_SECRET: ${JWT_SECRET:-your-jwt-secret-change-in-production}
      PORT: 3000
      CORS_ORIGIN: http://localhost
    volumes:
      - ./backend:/usr/src/app
      - /usr/src/app/node_modules
      - ./logs:/usr/src/app/logs
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "3000:3000"
    restart: unless-stopped
    networks:
      - bakery-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - REACT_APP_API_URL=http://localhost/api
    container_name: bakery-erp-frontend
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - bakery-network

  nginx:
    image: nginx:alpine
    container_name: bakery-erp-nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./logs/nginx:/var/log/nginx
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - frontend
      - backend
    restart: unless-stopped
    networks:
      - bakery-network

volumes:
  postgres_data:
    driver: local

networks:
  bakery-network:
    driver: bridge
EOFCOMPOSE

cat > .env.example << 'EOFENV'
DB_PASSWORD=bakery_pass_2024
POSTGRES_DB=bakery_erp
POSTGRES_USER=bakery_user
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-min-32-chars
NODE_ENV=production
PORT=3000
REACT_APP_API_URL=http://localhost/api
EOFENV

cp .env.example .env

cat > .gitignore << 'EOFGITIGNORE'
node_modules/
npm-debug.log*
.env
.env.local
/frontend/build
/backend/dist
logs/
*.log
.DS_Store
.vscode/
.idea/
postgres_data/
EOFGITIGNORE

cat > README.md << 'EOFREADME'
# 🍰 Bakery ERP/MRP System

Система управления кондитерским производством

## Быстрый старт

