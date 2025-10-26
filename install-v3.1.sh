#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP v3.1 - Полная рабочая версия
# Исправления + Расширенный функционал + Локализация
###############################################################################

set -e

echo "🍰 Bakery ERP v3.1 - Полная версия"
echo "===================================="
echo ""

echo "📂 Создаю структуру..."
mkdir -p backend frontend/src/{pages,components,i18n} frontend/public

###############################################################################
# DOCKER-COMPOSE.YML (ИСПРАВЛЕНО)
###############################################################################

cat > docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:16-alpine
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
      retries: 5

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://bakery:bakery123@db:5432/bakery_erp
      JWT_SECRET: my-secret-key-2024
    depends_on:
      db:
        condition: service_healthy

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend

volumes:
  pgdata:
EOF

###############################################################################
# BACKEND
###############################################################################

cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "server.js"]
EOF

cat > backend/package.json << 'EOF'
{
  "name": "bakery-backend",
  "version": "3.1.0",
  "type": "module",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "sequelize": "^6.35.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2"
  }
}
EOF

cat > backend/server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import { Sequelize, DataTypes } from 'sequelize';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const app = express();
app.use(cors());
app.use(express.json());

const sequelize = new Sequelize(process.env.DATABASE_URL, { logging: false });

// MODELS
const User = sequelize.define('User', {
  login: { type: DataTypes.STRING, unique: true },
  password: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  phone: DataTypes.STRING,
  telegram: DataTypes.STRING,
  role: { type: DataTypes.ENUM('admin', 'manager'), defaultValue: 'manager' }
});

const Supplier = sequelize.define('Supplier', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING
});

const Client = sequelize.define('Client', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING,
  type: { type: DataTypes.ENUM('wholesale', 'retail1', 'retail2'), defaultValue: 'wholesale' }
});

const Component = sequelize.define('Component', {
  name: DataTypes.STRING,
  price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  quantity: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  unit: { type: DataTypes.STRING, defaultValue: 'кг' }
});

const Recipe = sequelize.define('Recipe', {
  name: DataTypes.STRING,
  outputWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 1 }
});

const RecipeItem = sequelize.define('RecipeItem', {
  recipeId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  weight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 }
});

const Product = sequelize.define('Product', {
  name: DataTypes.STRING,
  recipeId: DataTypes.INTEGER,
  boxGrossWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  boxNetWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  basePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Settings = sequelize.define('Settings', {
  wholesaleMarkup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 10 },
  retail1Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 40 },
  retail2Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 70 }
});

// ASSOCIATIONS
RecipeItem.belongsTo(Component, { foreignKey: 'componentId' });

// AUTH MIDDLEWARE
const auth = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) throw new Error();
    jwt.verify(token, process.env.JWT_SECRET || 'my-secret-key-2024');
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

// AUTH
app.post('/api/auth/login', async (req, res) => {
  try {
    const { login, password } = req.body;
    const user = await User.findOne({ where: { login } });
    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'my-secret-key-2024', { expiresIn: '24h' });
    res.json({ token, user: { id: user.id, login: user.login, name: user.name, role: user.role } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// USERS
app.get('/api/users', auth, async (req, res) => {
  const users = await User.findAll({ attributes: { exclude: ['password'] } });
  res.json(users);
});

app.post('/api/users', auth, async (req, res) => {
  const { login, password, name, email, phone, telegram, role } = req.body;
  const hashed = await bcrypt.hash(password, 10);
  const user = await User.create({ login, password: hashed, name, email, phone, telegram, role });
  res.json({ id: user.id, login, name, email, phone, telegram, role });
});

app.put('/api/users/:id', auth, async (req, res) => {
  const { name, email, phone, telegram, password } = req.body;
  const user = await User.findByPk(req.params.id);
  if (password) {
    user.password = await bcrypt.hash(password, 10);
  }
  user.name = name;
  user.email = email;
  user.phone = phone;
  user.telegram = telegram;
  await user.save();
  res.json({ id: user.id, name, email, phone, telegram });
});

// SUPPLIERS
app.get('/api/suppliers', auth, async (req, res) => res.json(await Supplier.findAll()));
app.post('/api/suppliers', auth, async (req, res) => res.json(await Supplier.create(req.body)));
app.put('/api/suppliers/:id', auth, async (req, res) => {
  await Supplier.update(req.body, { where: { id: req.params.id } });
  res.json(await Supplier.findByPk(req.params.id));
});

// CLIENTS
app.get('/api/clients', auth, async (req, res) => res.json(await Client.findAll()));
app.post('/api/clients', auth, async (req, res) => res.json(await Client.create(req.body)));
app.put('/api/clients/:id', auth, async (req, res) => {
  await Client.update(req.body, { where: { id: req.params.id } });
  res.json(await Client.findByPk(req.params.id));
});

// COMPONENTS
app.get('/api/components', auth, async (req, res) => res.json(await Component.findAll()));
app.post('/api/components', auth, async (req, res) => res.json(await Component.create(req.body)));
app.put('/api/components/:id', auth, async (req, res) => {
  await Component.update(req.body, { where: { id: req.params.id } });
  res.json(await Component.findByPk(req.params.id));
});

// RECIPES
app.get('/api/recipes', auth, async (req, res) => res.json(await Recipe.findAll()));
app.post('/api/recipes', auth, async (req, res) => {
  const recipe = await Recipe.create({ name: req.body.name, outputWeight: req.body.outputWeight });
  if (req.body.items) {
    for (const item of req.body.items) {
      await RecipeItem.create({ recipeId: recipe.id, componentId: item.componentId, weight: item.weight });
    }
  }
  res.json(recipe);
});

app.get('/api/recipes/:id', auth, async (req, res) => {
  const recipe = await Recipe.findByPk(req.params.id);
  const items = await RecipeItem.findAll({ 
    where: { recipeId: req.params.id }, 
    include: [Component] 
  });
  res.json({ ...recipe.toJSON(), items });
});

// PRODUCTS
app.get('/api/products', auth, async (req, res) => {
  const products = await Product.findAll();
  res.json(products);
});

app.post('/api/products', auth, async (req, res) => {
  const product = await Product.create(req.body);
  res.json(product);
});

app.get('/api/products/:id/prices', auth, async (req, res) => {
  const product = await Product.findByPk(req.params.id);
  const settings = await Settings.findOne();
  const prices = {
    base: parseFloat(product.basePrice),
    wholesale: parseFloat(product.basePrice) * (1 + settings.wholesaleMarkup / 100),
    retail1: parseFloat(product.basePrice) * (1 + settings.retail1Markup / 100),
    retail2: parseFloat(product.basePrice) * (1 + settings.retail2Markup / 100)
  };
  res.json(prices);
});

// SETTINGS
app.get('/api/settings', auth, async (req, res) => {
  let settings = await Settings.findOne();
  if (!settings) {
    settings = await Settings.create({});
  }
  res.json(settings);
});

app.put('/api/settings', auth, async (req, res) => {
  let settings = await Settings.findOne();
  if (!settings) {
    settings = await Settings.create(req.body);
  } else {
    await settings.update(req.body);
  }
  res.json(settings);
});

// INIT
sequelize.sync({ force: true }).then(async () => {
  const hashed = await bcrypt.hash('admin', 10);
  await User.create({ login: 'admin', password: hashed, name: 'Administrator', role: 'admin' });
  await Settings.create({});
  console.log('✅ Database initialized');
  app.listen(3000, () => console.log('🚀 Backend on :3000'));
});
EOF

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
  "version": "3.1.0",
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
  <title>Bakery ERP v3.1</title>
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
input, select, textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; }
table th { background: #f7fafc; padding: 12px; text-align: left; border-bottom: 2px solid #e2e8f0; }
table td { padding: 12px; border-bottom: 1px solid #e2e8f0; }
.login-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
.login-card { background: white; padding: 40px; border-radius: 12px; width: 400px; }
.modal { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-content { background: white; padding: 30px; border-radius: 12px; width: 500px; max-height: 80vh; overflow-y: auto; }
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
      type: 'Тип',
      wholesale: 'Оптовий',
      retail1: 'Роздріб 1',
      retail2: 'Роздріб 2',
      price: 'Ціна',
      quantity: 'Кількість',
      basePrice: 'Базова ціна',
      markup: 'Наценка',
      weight: 'Вага'
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
      type: 'Тип',
      wholesale: 'Оптовый',
      retail1: 'Розница 1',
      retail2: 'Розница 2',
      price: 'Цена',
      quantity: 'Количество',
      basePrice: 'Базовая цена',
      markup: 'Наценка',
      weight: 'Вес'
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
      type: 'Type',
      wholesale: 'Wholesale',
      retail1: 'Retail 1',
      retail2: 'Retail 2',
      price: 'Price',
      quantity: 'Quantity',
      basePrice: 'Base Price',
      markup: 'Markup',
      weight: 'Weight'
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
        <h2 style={{textAlign: 'center'}}>🍰 Bakery ERP v3.1</h2>
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
      <p>✅ Система v3.1 запущена успішно!</p>
    </div>
  );
}

export default Dashboard;
EOF

cat > frontend/src/pages/UsersPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState({ login: '', password: '', name: '', email: '', phone: '', telegram: '' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = () => {
    axios.get('http://localhost:3000/api/users', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setUsers(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/users/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadUsers(); setEditing(null); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); });
    } else {
      axios.post('http://localhost:3000/api/users', { ...form, role: 'manager' }, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadUsers(); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); });
    }
  };

  const handleEdit = (user) => {
    setForm({ login: user.login, password: '', name: user.name, email: user.email || '', phone: user.phone || '', telegram: user.telegram || '' });
    setEditing(user.id);
  };

  return (
    <div className="card">
      <h2>{t('users')}</h2>
      <div className="form-group">
        <label>{t('login')}</label>
        <input value={form.login} onChange={e => setForm({...form, login: e.target.value})} disabled={editing} />
      </div>
      <div className="form-group">
        <label>{t('password')}</label>
        <input type="password" value={form.password} onChange={e => setForm({...form, password: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('name')}</label>
        <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('email')}</label>
        <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('phone')}</label>
        <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('telegram')}</label>
        <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} />
      </div>
      <button className="btn btn-primary" onClick={handleSubmit}>
        {editing ? t('save') : t('add')}
      </button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('login')}</th><th>{t('name')}</th><th>{t('email')}</th><th>{t('phone')}</th><th></th></tr></thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.login}</td>
              <td>{u.name}</td>
              <td>{u.email}</td>
              <td>{u.phone}</td>
              <td><button className="btn btn-warning" onClick={() => handleEdit(u)}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default UsersPage;
EOF

cat > frontend/src/pages/SuppliersPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function SuppliersPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/suppliers', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/suppliers/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '' }); });
    } else {
      axios.post('http://localhost:3000/api/suppliers', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', phone: '', email: '', telegram: '' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('suppliers')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder={t('phone')} />
      <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder={t('email')} />
      <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder={t('telegram')} />
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('phone')}</th><th>{t('email')}</th><th>{t('telegram')}</th><th></th></tr></thead>
        <tbody>
          {items.map(s => (
            <tr key={s.id}>
              <td>{s.name}</td>
              <td>{s.phone}</td>
              <td>{s.email}</td>
              <td>{s.telegram}</td>
              <td><button className="btn btn-warning" onClick={() => { setForm(s); setEditing(s.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default SuppliersPage;
EOF

cat > frontend/src/pages/ClientsPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ClientsPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/clients', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/clients/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); });
    } else {
      axios.post('http://localhost:3000/api/clients', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('clients')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder={t('phone')} />
      <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder={t('email')} />
      <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder={t('telegram')} />
      <select value={form.type} onChange={e => setForm({...form, type: e.target.value})}>
        <option value="wholesale">{t('wholesale')} (+10%)</option>
        <option value="retail1">{t('retail1')} (+40%)</option>
        <option value="retail2">{t('retail2')} (+70%)</option>
      </select>
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('type')}</th><th>{t('phone')}</th><th>{t('email')}</th><th></th></tr></thead>
        <tbody>
          {items.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{t(c.type)}</td>
              <td>{c.phone}</td>
              <td>{c.email}</td>
              <td><button className="btn btn-warning" onClick={() => { setForm(c); setEditing(c.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ClientsPage;
EOF

cat > frontend/src/pages/ComponentsPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ComponentsPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', price: '', quantity: '', unit: 'кг' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/components', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/components/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); });
    } else {
      axios.post('http://localhost:3000/api/components', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('components')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.price} onChange={e => setForm({...form, price: e.target.value})} placeholder={t('price')} type="number" step="0.01" />
      <input value={form.quantity} onChange={e => setForm({...form, quantity: e.target.value})} placeholder={t('quantity')} type="number" step="0.001" />
      <select value={form.unit} onChange={e => setForm({...form, unit: e.target.value})}>
        <option>кг</option>
        <option>л</option>
        <option>шт</option>
      </select>
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('price')}</th><th>{t('quantity')}</th><th>Од.</th><th></th></tr></thead>
        <tbody>
          {items.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.price}</td>
              <td>{c.quantity}</td>
              <td>{c.unit}</td>
              <td><button className="btn btn-warning" onClick={() => { setForm(c); setEditing(c.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ComponentsPage;
EOF

cat > frontend/src/pages/ProductsPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [recipes, setRecipes] = useState([]);
  const [form, setForm] = useState({ name: '', recipeId: '', boxGrossWeight: '', boxNetWeight: '', basePrice: '' });
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadData();
    axios.get('http://localhost:3000/api/recipes', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setRecipes(res.data));
  }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/products', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setProducts(res.data));
  };

  const handleSubmit = () => {
    axios.post('http://localhost:3000/api/products', form, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => { loadData(); setForm({ name: '', recipeId: '', boxGrossWeight: '', boxNetWeight: '', basePrice: '' }); });
  };

  return (
    <div className="card">
      <h2>{t('products')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <select value={form.recipeId} onChange={e => setForm({...form, recipeId: e.target.value})}>
        <option value="">Оберіть рецепт</option>
        {recipes.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
      </select>
      <input value={form.boxGrossWeight} onChange={e => setForm({...form, boxGrossWeight: e.target.value})} placeholder="Брутто (кг)" type="number" step="0.01" />
      <input value={form.boxNetWeight} onChange={e => setForm({...form, boxNetWeight: e.target.value})} placeholder="Нетто (кг)" type="number" step="0.01" />
      <input value={form.basePrice} onChange={e => setForm({...form, basePrice: e.target.value})} placeholder={t('basePrice')} type="number" step="0.01" />
      <button className="btn btn-primary" onClick={handleSubmit}>{t('add')}</button>
      <table>
        <thead><tr><th>{t('name')}</th><th>Брутто</th><th>Нетто</th><th>{t('basePrice')}</th></tr></thead>
        <tbody>
          {products.map(p => (
            <tr key={p.id}>
              <td>{p.name}</td>
              <td>{p.boxGrossWeight} кг</td>
              <td>{p.boxNetWeight} кг</td>
              <td>{p.basePrice} грн</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ProductsPage;
EOF

cat > frontend/src/pages/RecipesPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function RecipesPage() {
  const [recipes, setRecipes] = useState([]);
  const [components, setComponents] = useState([]);
  const [form, setForm] = useState({ name: '', outputWeight: 1, items: [] });
  const [showModal, setShowModal] = useState(false);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadData();
    axios.get('http://localhost:3000/api/components', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setComponents(res.data));
  }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/recipes', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setRecipes(res.data));
  };

  const addItem = () => {
    setForm({...form, items: [...form.items, { componentId: '', weight: '' }]});
  };

  const updateItem = (idx, field, value) => {
    const items = [...form.items];
    items[idx][field] = value;
    setForm({...form, items});
  };

  const handleSubmit = () => {
    axios.post('http://localhost:3000/api/recipes', form, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => { loadData(); setForm({ name: '', outputWeight: 1, items: [] }); setShowModal(false); });
  };

  return (
    <div className="card">
      <h2>{t('recipes')}</h2>
      <button className="btn btn-primary" onClick={() => setShowModal(true)}>{t('add')}</button>
      <table>
        <thead><tr><th>{t('name')}</th><th>Вихід (кг)</th></tr></thead>
        <tbody>
          {recipes.map(r => <tr key={r.id}><td>{r.name}</td><td>{r.outputWeight}</td></tr>)}
        </tbody>
      </table>

      {showModal && (
        <div className="modal">
          <div className="modal-content">
            <h3>Новий рецепт</h3>
            <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
            <input value={form.outputWeight} onChange={e => setForm({...form, outputWeight: e.target.value})} placeholder="Вихід (кг)" type="number" step="0.01" />
            <h4>Склад:</h4>
            {form.items.map((item, idx) => (
              <div key={idx} style={{display: 'flex', gap: 10, marginBottom: 10}}>
                <select value={item.componentId} onChange={e => updateItem(idx, 'componentId', e.target.value)}>
                  <option value="">Оберіть компонент</option>
                  {components.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
                <input value={item.weight} onChange={e => updateItem(idx, 'weight', e.target.value)} placeholder="Вага на 1 кг" type="number" step="0.001" />
              </div>
            ))}
            <button className="btn btn-success" onClick={addItem}>+ Компонент</button>
            <div style={{marginTop: 20}}>
              <button className="btn btn-primary" onClick={handleSubmit}>{t('save')}</button>
              <button className="btn" onClick={() => { setShowModal(false); setForm({ name: '', outputWeight: 1, items: [] }); }}>{t('cancel')}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default RecipesPage;
EOF

cat > frontend/src/pages/SettingsPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function SettingsPage() {
  const [settings, setSettings] = useState({ wholesaleMarkup: 10, retail1Markup: 40, retail2Markup: 70 });
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    axios.get('http://localhost:3000/api/settings', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setSettings(res.data));
  }, []);

  const handleSave = () => {
    axios.put('http://localhost:3000/api/settings', settings, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => alert('Збережено!'));
  };

  return (
    <div className="card">
      <h2>{t('settings')}</h2>
      <div className="form-group">
        <label>{t('wholesale')} {t('markup')} (%)</label>
        <input value={settings.wholesaleMarkup} onChange={e => setSettings({...settings, wholesaleMarkup: e.target.value})} type="number" />
      </div>
      <div className="form-group">
        <label>{t('retail1')} {t('markup')} (%)</label>
        <input value={settings.retail1Markup} onChange={e => setSettings({...settings, retail1Markup: e.target.value})} type="number" />
      </div>
      <div className="form-group">
        <label>{t('retail2')} {t('markup')} (%)</label>
        <input value={settings.retail2Markup} onChange={e => setSettings({...settings, retail2Markup: e.target.value})} type="number" />
      </div>
      <button className="btn btn-primary" onClick={handleSave}>{t('save')}</button>
    </div>
  );
}

export default SettingsPage;
EOF

cat > .gitignore << 'EOF'
node_modules
.env
/frontend/build
pgdata
*.log
EOF

cat > README.md << 'EOF'
# 🍰 Bakery ERP v3.1

## Возможности
- ✅ Авторизация (JWT)
- ✅ Пользователи (Email, Phone, Telegram, редактирование)
- ✅ Поставщики (полные контакты)
- ✅ Клиенты (типы: Оптовый/Розн1/Розн2)
- ✅ Компоненты (сырьё: название, цена, количество)
- ✅ Рецепты (конструктор из компонентов)
- ✅ Товары (брутто/нетто, автоценообразование)
- ✅ Настройки (управление наценками)
- ✅ Локализация (УКР/РУС/ENG)

## Запуск
```bash
chmod +x install-v3.1.sh
./install-v3.1.sh
docker compose up -d --build
```

**Логин:** admin / **Пароль:** admin  
**URL:** http://localhost
EOF

echo ""
echo "✅ v3.1 создана с полным функционалом!"
echo ""
echo "🚀 Запуск:"
echo "  docker compose down --volumes"
echo "  docker compose up -d --build"
echo ""
echo "🔐 admin / admin"
echo "📍 http://localhost"
echo ""
