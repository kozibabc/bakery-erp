#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 FULL - Part 1/10
# Docker + Base Structure + .env
###############################################################################

set -e

echo "🍰 Bakery ERP v4.1 FULL - Part 1/10"
echo "==================================="
echo "Docker Compose + Base Structure"
echo ""

# Очистка
rm -rf backend frontend docker-compose.yml .env .gitignore

# Структура
mkdir -p backend/src/{models,routes,middleware,services}
mkdir -p frontend/src/{components,pages,services,i18n}
mkdir -p frontend/public

###############################################################################
# DOCKER-COMPOSE.YML
###############################################################################

cat > docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:16-alpine
    container_name: bakery-db
    environment:
      POSTGRES_USER: bakery
      POSTGRES_PASSWORD: bakery123
      POSTGRES_DB: bakery_erp
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "bakery", "-d", "bakery_erp"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: unless-stopped
    networks:
      - bakery-net

  backend:
    build: ./backend
    container_name: bakery-backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://bakery:bakery123@db:5432/bakery_erp
      JWT_SECRET: my-secret-key-2024
      NODE_ENV: production
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - bakery-net
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build: ./frontend
    container_name: bakery-frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - bakery-net

volumes:
  pgdata:
    driver: local

networks:
  bakery-net:
    driver: bridge
EOF

###############################################################################
# .gitignore
###############################################################################

cat > .gitignore << 'EOF'
node_modules/
.env
.env.local
/frontend/build
logs/
*.log
.DS_Store
.vscode/
pgdata/
EOF

###############################################################################
# .env
###############################################################################

cat > .env << 'EOF'
DATABASE_URL=postgresql://bakery:bakery123@db:5432/bakery_erp
JWT_SECRET=my-secret-key-2024
NODE_ENV=production
EOF

echo "✅ Part 1/10 завершена"
echo ""
echo "Создано:"
echo "  ✅ docker-compose.yml"
echo "  ✅ .gitignore"
echo "  ✅ .env"
echo "  ✅ Структура директорий"
echo ""
echo "▶️  Запустите: ./install-v4.1-part2.sh"
echo ""
