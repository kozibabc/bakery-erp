#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP v3.2 - Part 2 (Frontend)
# Запустите ПОСЛЕ install-v3.2-part1.sh
###############################################################################

set -e

echo "🍰 Bakery ERP v3.2 - Frontend (Part 2)"
echo "======================================"
echo ""

###############################################################################
# FRONTEND
###############################################################################

cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
CMD ["nginx", "-g", "daemon off;"]
EOF

cat > frontend/package.json << 'EOF'
{
  "name": "bakery-frontend",
  "version": "3.2.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.2",
    "i18next": "^23.7.6",
    "react-i18next": "^13.5.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  },
  "devDependencies": {
    "react-scripts": "5.0.1"
  }
}
EOF

cat > frontend/nginx.conf << 'EOF'
server {
  listen 80;
  root /usr/share/nginx/html;
  index index.html;
  location / {
    try_files $uri /index.html;
  }
}
EOF

cat > frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="uk">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Bakery ERP v3.2</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>
EOF

cat > frontend/src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import './i18n/config';
import App from './App';

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
EOF

cat > frontend/src/index.css << 'EOF'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, sans-serif; background: #f5f7fa; }
.app { display: flex; min-height: 100vh; }
.sidebar { width: 250px; background: linear-gradient(180deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; display: flex; flex-direction: column; }
.sidebar h1 { font-size: 20px; margin-bottom: 30px; }
.sidebar nav a { display: block; color: white; text-decoration: none; padding: 10px; margin: 5px 0; border-radius: 5px; }
.sidebar nav a:hover, .sidebar nav a.active { background: rgba(255,255,255,0.2); }
.sidebar .lang-selector { margin-top: auto; padding: 10px 0; }
.sidebar .lang-selector select { width: 100%; padding: 8px; border-radius: 5px; border: none; }
.main { flex: 1; padding: 30px; }
.card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
.form-group { margin-bottom: 15px; }
.form-group label { display: block; margin-bottom: 5px; font-weight: 500; }
.btn { padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: 500; margin-right: 10px; }
.btn-primary { background: #667eea; color: white; }
.btn-success { background: #48bb78; color: white; }
.btn-warning { background: #ed8936; color: white; }
.btn-danger { background: #f56565; color: white; }
input, select, textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; }
table th { background: #f7fafc; padding: 12px; text-align: left; border-bottom: 2px solid #e2e8f0; }
table td { padding: 12px; border-bottom: 1px solid #e2e8f0; }
.login-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
.login-card { background: white; padding: 40px; border-radius: 12px; width: 400px; }
.modal { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-content { background: white; padding: 30px; border-radius: 12px; width: 600px; max-height: 80vh; overflow-y: auto; }
.telegram-link { color: #0088cc; text-decoration: none; }
.telegram-link:hover { text-decoration: underline; }
EOF

cat > frontend/src/i18n/config.js << 'EOF'
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  uk: {
    translation: {
      home: 'Головна',
      users: 'Користувачі',
      suppliers: 'Постачальники',
      clients: 'Клієнти',
      components: 'Компоненти',
      products: 'Товари',
      recipes: 'Рецепти',
      orders: 'Замовлення',
      analytics: 'Аналітика',
      settings: 'Налаштування',
      logout: 'Вихід',
      login: 'Логін',
      password: 'Пароль',
      name: 'Ім\'я',
      email: 'Email',
      phone: 'Телефон',
      telegram: 'Telegram',
      add: 'Додати',
      edit: 'Редагувати',
      save: 'Зберегти',
      cancel: 'Скасувати',
      delete: 'Видалити',
      type: 'Тип',
      wholesale: 'Оптовий',
      retail1: 'Роздріб 1',
      retail2: 'Роздріб 2',
      price: 'Ціна',
      quantity: 'Кількість',
      basePrice: 'Базова ціна',
      markup: 'Наценка',
      weight: 'Вага',
      generatePDF: 'Генерувати PDF',
      downloadOrder: 'Завантажити замовлення'
    }
  },
  ru: {
    translation: {
      home: 'Главная',
      users: 'Пользователи',
      suppliers: 'Поставщики',
      clients: 'Клиенты',
      components: 'Компоненты',
      products: 'Товары',
      recipes: 'Рецепты',
      orders: 'Заказы',
      analytics: 'Аналитика',
      settings: 'Настройки',
      logout: 'Выход',
      login: 'Логин',
      password: 'Пароль',
      name: 'Имя',
      email: 'Email',
      phone: 'Телефон',
      telegram: 'Telegram',
      add: 'Добавить',
      edit: 'Редактировать',
      save: 'Сохранить',
      cancel: 'Отмена',
      delete: 'Удалить',
      type: 'Тип',
      wholesale: 'Оптовый',
      retail1: 'Розница 1',
      retail2: 'Розница 2',
      price: 'Цена',
      quantity: 'Количество',
      basePrice: 'Базовая цена',
      markup: 'Наценка',
      weight: 'Вес',
      generatePDF: 'Генерировать PDF',
      downloadOrder: 'Скачать заказ'
    }
  },
  en: {
    translation: {
      home: 'Home',
      users: 'Users',
      suppliers: 'Suppliers',
      clients: 'Clients',
      components: 'Components',
      products: 'Products',
      recipes: 'Recipes',
      orders: 'Orders',
      analytics: 'Analytics',
      settings: 'Settings',
      logout: 'Logout',
      login: 'Login',
      password: 'Password',
      name: 'Name',
      email: 'Email',
      phone: 'Phone',
      telegram: 'Telegram',
      add: 'Add',
      edit: 'Edit',
      save: 'Save',
      cancel: 'Cancel',
      delete: 'Delete',
      type: 'Type',
      wholesale: 'Wholesale',
      retail1: 'Retail 1',
      retail2: 'Retail 2',
      price: 'Price',
      quantity: 'Quantity',
      basePrice: 'Base Price',
      markup: 'Markup',
      weight: 'Weight',
      generatePDF: 'Generate PDF',
      downloadOrder: 'Download Order'
    }
  }
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'uk',
  fallbackLng: 'en',
  interpolation: { escapeValue: false }
});

export default i18n;
EOF

cat > frontend/src/components/TelegramLink.js << 'EOF'
import React from 'react';

function TelegramLink({ username }) {
  if (!username) return null;
  const cleanUsername = username.replace('@', '');
  return (
    <a href={`https://t.me/${cleanUsername}`} target="_blank" rel="noopener noreferrer" className="telegram-link">
      @{cleanUsername}
    </a>
  );
}

export default TelegramLink;
EOF

cat > frontend/src/App.js << 'EOF'
import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate, NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoginPage from './pages/LoginPage';
import Dashboard from './pages/Dashboard';
import UsersPage from './pages/UsersPage';
import SuppliersPage from './pages/SuppliersPage';
import ClientsPage from './pages/ClientsPage';
import ComponentsPage from './pages/ComponentsPage';
import ProductsPage from './pages/ProductsPage';
import RecipesPage from './pages/RecipesPage';
import OrdersPage from './pages/OrdersPage';
import AnalyticsPage from './pages/AnalyticsPage';
import SettingsPage from './pages/SettingsPage';

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const { t, i18n } = useTranslation();

  const handleLogin = (newToken, user) => {
    localStorage.setItem('token', newToken);
    localStorage.setItem('user', JSON.stringify(user));
    setToken(newToken);
  };

  const handleLogout = () => {
    localStorage.clear();
    setToken(null);
  };

  if (!token) return <LoginPage onLogin={handleLogin} />;

  return (
    <BrowserRouter>
      <div className="app">
        <div className="sidebar">
          <h1>🍰 Sazhenko</h1>
          <nav>
            <NavLink to="/" end>{t('home')}</NavLink>
            <NavLink to="/users">👤 {t('users')}</NavLink>
            <NavLink to="/suppliers">🚚 {t('suppliers')}</NavLink>
            <NavLink to="/clients">👥 {t('clients')}</NavLink>
            <NavLink to="/components">📦 {t('components')}</NavLink>
            <NavLink to="/products">🍰 {t('products')}</NavLink>
            <NavLink to="/recipes">📋 {t('recipes')}</NavLink>
            <NavLink to="/orders">📝 {t('orders')}</NavLink>
            <NavLink to="/analytics">📊 {t('analytics')}</NavLink>
            <NavLink to="/settings">⚙️ {t('settings')}</NavLink>
          </nav>
          <div className="lang-selector">
            <select value={i18n.language} onChange={e => i18n.changeLanguage(e.target.value)}>
              <option value="uk">🇺🇦 Українська</option>
              <option value="ru">🇷🇺 Русский</option>
              <option value="en">🇬🇧 English</option>
            </select>
          </div>
          <button className="btn btn-primary" onClick={handleLogout} style={{marginTop: 20, width: '100%'}}>
            {t('logout')}
          </button>
        </div>
        <div className="main">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/suppliers" element={<SuppliersPage />} />
            <Route path="/clients" element={<ClientsPage />} />
            <Route path="/components" element={<ComponentsPage />} />
            <Route path="/products" element={<ProductsPage />} />
            <Route path="/recipes" element={<RecipesPage />} />
            <Route path="/orders" element={<OrdersPage />} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/settings" element={<SettingsPage />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </div>
      </div>
    </BrowserRouter>
  );
}

export default App;
EOF

cat > frontend/src/pages/LoginPage.js << 'EOF'
import React, { useState } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function LoginPage({ onLogin }) {
  const [login, setLogin] = useState('admin');
  const [password, setPassword] = useState('admin');
  const { t } = useTranslation();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await axios.post('http://localhost:3000/api/auth/login', { login, password });
      onLogin(res.data.token, res.data.user);
    } catch {
      alert('Помилка входу');
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <h2 style={{textAlign: 'center'}}>🍰 Bakery ERP v3.2</h2>
        <form onSubmit={handleSubmit}>
          <input value={login} onChange={e => setLogin(e.target.value)} placeholder={t('login')} />
          <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder={t('password')} />
          <button type="submit" className="btn btn-primary" style={{width: '100%'}}>
            {t('login')}
          </button>
        </form>
      </div>
    </div>
  );
}

export default LoginPage;
EOF

cat > frontend/src/pages/Dashboard.js << 'EOF'
import React from 'react';
import { useTranslation } from 'react-i18next';

function Dashboard() {
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const { t } = useTranslation();
  
  return (
    <div className="card">
      <h2>{t('home')}</h2>
      <p>Вітаємо, {user.name || 'користувач'}!</p>
      <p>✅ Система v3.2 запущена успішно!</p>
      <h3>Нові можливості:</h3>
      <ul>
        <li>📝 Замовлення з генерацією PDF</li>
        <li>📊 Аналітика продажів</li>
        <li>💰 Автоматичне ценообразование</li>
        <li>📋 Розширені рецепти</li>
      </ul>
    </div>
  );
}

export default Dashboard;
EOF

echo "✅ Frontend Part 2 створено!"
echo ""
echo "📋 Наступний крок: створіть окремі сторінки"
echo "   (UsersPage, ProductsPage, OrdersPage, etc.)"
echo ""
