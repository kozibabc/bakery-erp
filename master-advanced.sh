#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 - MASTER ADVANCED INSTALLER
# Полная установка с расширенным функционалом
###############################################################################

set -e

echo "🍰 Bakery ERP v4.1 - MASTER ADVANCED INSTALLER"
echo "=============================================="
echo ""
echo "Этот скрипт установит ПОЛНЫЙ функционал:"
echo "  ✅ Базовая система"
echo "  ✅ Все CRUD страницы"
echo "  ✅ Закупки → Склад (автообновление)"
echo "  ✅ Рецепты с компонентами"
echo "  ✅ Замовлення с товарами"
echo "  ✅ Користувачі"
echo "  ✅ Аналітика"
echo ""
read -p "Продолжить? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено"
    exit 1
fi

###############################################################################
# ШАГ 1: Базовая установка
###############################################################################

echo ""
echo "📦 Шаг 1/7: Базовая система..."
echo ""

if [ -f "./install-v4-complete.sh" ]; then
    chmod +x ./install-v4-complete.sh
    ./install-v4-complete.sh
else
    echo "❌ Файл install-v4-complete.sh не найден!"
    exit 1
fi

###############################################################################
# ШАГ 2-4: Базовые страницы
###############################################################################

echo ""
echo "📄 Шаг 2/7: Базовые страницы (Clients, Suppliers)..."
echo ""
[ -f "./add-pages-part1.sh" ] && chmod +x ./add-pages-part1.sh && ./add-pages-part1.sh

echo ""
echo "📄 Шаг 3/7: Базовые страницы (Components, Products)..."
echo ""
[ -f "./add-pages-part2.sh" ] && chmod +x ./add-pages-part2.sh && ./add-pages-part2.sh

echo ""
echo "📄 Шаг 4/7: Базовые страницы (Orders)..."
echo ""
[ -f "./add-pages-part3.sh" ] && chmod +x ./add-pages-part3.sh && ./add-pages-part3.sh

###############################################################################
# ШАГ 5-7: Advanced Features
###############################################################################

echo ""
echo "🚀 Шаг 5/7: Advanced Features (Purchases + Stock)..."
echo ""
if [ -f "./add-advanced-part1.sh" ]; then
    chmod +x ./add-advanced-part1.sh
    ./add-advanced-part1.sh
else
    echo "⚠️  add-advanced-part1.sh не найден, пропускаем..."
fi

echo ""
echo "🚀 Шаг 6/7: Advanced Features (Recipes + Users)..."
echo ""
if [ -f "./add-advanced-part2.sh" ]; then
    chmod +x ./add-advanced-part2.sh
    ./add-advanced-part2.sh
else
    echo "⚠️  add-advanced-part2.sh не найден, пропускаем..."
fi

echo ""
echo "🚀 Шаг 7/7: Advanced Features (Orders + Analytics)..."
echo ""
if [ -f "./add-advanced-part3.sh" ]; then
    chmod +x ./add-advanced-part3.sh
    ./add-advanced-part3.sh
else
    echo "⚠️  add-advanced-part3.sh не найден, пропускаем..."
fi

###############################################################################
# ФИНАЛ: Запуск системы
###############################################################################

echo ""
echo "🚀 Запуск системы..."
echo ""

# Остановка старых контейнеров
docker compose down 2>/dev/null || true

# Запуск новых
docker compose up -d --build

echo ""
echo "✅ УСТАНОВКА ЗАВЕРШЕНА!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Bakery ERP v4.1 ADVANCED успешно установлена!"
echo ""
echo "📋 Полный функционал:"
echo "   ✅ Клієнти - повний CRUD"
echo "   ✅ Постачальники - додавання"
echo "   ✅ Компоненти - додавання"
echo "   ✅ Закупки - автооновлення складу"
echo "   ✅ Склад - залишки + середня ціна"
echo "   ✅ Рецепти - з компонентами та редагуванням"
echo "   ✅ Товари - додавання"
echo "   ✅ Замовлення - створення + виконання"
echo "   ✅ Користувачі - CRUD"
echo "   ✅ Аналітика - статистика системи"
echo ""
echo "🔥 НОВІ МОЖЛИВОСТІ:"
echo "   📦 Закупка → автоматично оновлює склад"
echo "   📊 Склад → середня зважена ціна"
echo "   📋 Рецепти → додавання компонентів з вагою"
echo "   📝 Замовлення → додавання товарів"
echo "   ✅ Виконання замовлення → списання зі складу"
echo "   👤 Користувачі → додавання/редагування"
echo "   📊 Аналітика → загальна статистика"
echo ""
echo "🌐 Откройте в браузере:"
echo "   http://localhost"
echo ""
echo "🔑 Логин:"
echo "   Логін: admin"
echo "   Пароль: admin"
echo ""
echo "📊 Проверка статуса:"
echo "   docker compose ps"
echo ""
echo "📝 Логи:"
echo "   docker compose logs -f backend"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
