#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP - Полная автоматическая установка
# Включает: Backend (Node.js/Express/Sequelize), Frontend (React/i18n)
# Авторизация JWT, CRUD, многоязычность, украинский брендинг
###############################################################################

set -e

echo "🍰 Sazhenko Bakery ERP - Автоматическая установка"
echo "=================================================="
echo ""

if [ ! -d ".git" ]; then
    echo "❌ Запустите скрипт в корне git репозитория!"
    echo "git clone git@github.com:kozibabc/bakery-erp.git && cd bakery-erp"
    exit 1
fi

echo "✅ Git репозиторий найден"
mkdir -p backend/src/{config,routes,models,services,middleware}
mkdir -p frontend/src/{pages,components,services,utils}
mkdir -p frontend/public
mkdir -p nginx/conf.d
mkdir -p database/init
mkdir -p logs
echo "✅ Директории созданы"
echo ""

### КОРНЕВЫЕ ФАЙЛЫ

cat > docker-compose.yml << 'EOFCOMPOSE'
version: '3.8'
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: bakery_user
      POSTGRES_PASSWORD: bakery_pass_2024
      POSTGRES_DB: bakery_erp
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    networks:
      - bakery

  backend:
    build: ./backend
    environment:
      DB_HOST: db
      DB_USER: bakery_user
      DB_PASSWORD: bakery_pass_2024
      DB_NAME: bakery_erp
      JWT_SECRET: super-secret-jwt-key-change-this
      NODE_ENV: production
      PORT: 3000
    ports:
      - "3000:3000"
    depends_on:
      - db
    networks:
      - bakery

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - bakery

volumes:
  pg_data:

networks:
  bakery:
EOFCOMPOSE

cat > .env.example << 'EOFENV'
DB_PASSWORD=bakery_pass_2024
JWT_SECRET=super-secret-jwt-key-change-this
EOFENV

cp .env.example .env

cat > .gitignore << 'EOFGIT'
node_modules/
.env
.env.local
/frontend/build
logs/
*.log
.DS_Store
.vscode/
postgres_data/
EOFGIT

cat > README.md << 'EOFREADME'
# 🍰 Кондітерські вироби Sazhenko - ERP System

Система управління виробництвом кондитерських виробів

## Быстрий старт

```bash
git clone git@github.com:kozibabc/bakery-erp.git
cd bakery-erp
docker compose up -d --build
docker compose exec backend npm run db:seed
```

Логін: `admin` / Пароль: `admin`

Откройте: http://localhost

## Мови

Українська 🇺🇦 | Русский 🇷🇺 | English 🇬🇧

MIT License
EOFREADME

### BACKEND

cat > backend/Dockerfile << 'EOFBDOCK'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOFBDOCK

cat > backend/package.json << 'EOFBPKG'
{
  "name": "sazhenko-bakery-backend",
  "version": "1.0.0",
  "type": "module",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "db:seed": "node src/seed.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.2",
    "pg": "^8.11.3",
    "sequelize": "^6.35.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOFBPKG

cat > backend/src/app.js << 'EOFAPP'
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import db from './db.js';
import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import productRoutes from './routes/products.js';
import clientRoutes from './routes/clients.js';
import supplierRoutes from './routes/suppliers.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (_, res) => res.json({ ok: true }));
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/suppliers', supplierRoutes);

db.sync().then(() => {
  app.listen(3000, () => console.log('✅ API: http://localhost:3000'));
}).catch(e => console.error('DB Error:', e));
EOFAPP

cat > backend/src/db.js << 'EOFDB'
import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';
import User from './models/User.js';
import Product from './models/Product.js';
import Client from './models/Client.js';
import Supplier from './models/Supplier.js';

dotenv.config();

const seq = new Sequelize(
  process.env.DB_NAME || 'bakery_erp',
  process.env.DB_USER || 'bakery_user',
  process.env.DB_PASSWORD || 'bakery_pass_2024',
  {
    host: process.env.DB_HOST || 'db',
    port: 5432,
    dialect: 'postgres',
    logging: false
  }
);

User(seq);
Product(seq);
Client(seq);
Supplier(seq);

export default seq;
EOFDB

cat > backend/src/models/User.js << 'EOFUSER'
import { DataTypes } from 'sequelize';
import bcrypt from 'bcryptjs';

export default (seq) => {
  const User = seq.define('User', {
    login: { type: DataTypes.STRING, unique: true, allowNull: false },
    password: { type: DataTypes.STRING, allowNull: false },
    name: DataTypes.STRING,
    phone: DataTypes.STRING,
    description: DataTypes.STRING,
    language: { type: DataTypes.ENUM('ru', 'en', 'uk'), defaultValue: 'uk' },
    isAdmin: { type: DataTypes.BOOLEAN, defaultValue: false }
  });

  User.beforeCreate(async u => {
    u.password = await bcrypt.hash(u.password, 10);
  });

  User.prototype.validatePassword = function(pwd) {
    return bcrypt.compare(pwd, this.password);
  };

  return User;
};
EOFUSER

cat > backend/src/models/Product.js << 'EOFPROD'
import { DataTypes } from 'sequelize';
export default (seq) => seq.define('Product', {
  name: { type: DataTypes.STRING, allowNull: false },
  code: { type: DataTypes.STRING, unique: true },
  description: DataTypes.STRING,
  netWeight: DataTypes.DECIMAL,
  unitsPerBox: DataTypes.INTEGER
});
EOFPROD

cat > backend/src/models/Client.js << 'EOFCLIENT'
import { DataTypes } from 'sequelize';
export default (seq) => seq.define('Client', {
  name: { type: DataTypes.STRING, allowNull: false },
  contact: DataTypes.STRING,
  phone: DataTypes.STRING,
  priceTier: DataTypes.ENUM('wholesale', 'retail1', 'retail2')
});
EOFCLIENT

cat > backend/src/models/Supplier.js << 'EOFSUP'
import { DataTypes } from 'sequelize';
export default (seq) => seq.define('Supplier', {
  name: { type: DataTypes.STRING, allowNull: false },
  contact: DataTypes.STRING,
  phone: DataTypes.STRING
});
EOFSUP

cat > backend/src/routes/auth.js << 'EOFAUTH'
import express from 'express';
import jwt from 'jsonwebtoken';
import { models } from 'sequelize';
import db from '../db.js';

const router = express.Router();
const User = db.models.User;

router.post('/login', async (req, res) => {
  try {
    const { login, password } = req.body;
    const user = await User.findOne({ where: { login } });
    if (!user || !(await user.validatePassword(password))) {
      return res.status(401).json({ msg: 'Invalid' });
    }
    const token = jwt.sign({ id: user.id, login: user.login, language: user.language }, process.env.JWT_SECRET, { expiresIn: '8h' });
    res.json({ token, user: { id: user.id, login: user.login, name: user.name, language: user.language } });
  } catch (e) {
    res.status(500).json({ msg: 'Error' });
  }
});

export default router;
EOFAUTH

cat > backend/src/routes/users.js << 'EOFUSERS'
import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const User = db.models.User;

function auth(req, res, next) {
  try {
    const token = req.headers?.authorization?.split(' ')[1];
    if (!token) throw new Error();
    jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ msg: 'Not authorized' });
  }
}

router.get('/', auth, async (_, res) => {
  res.json(await User.findAll({ attributes: { exclude: ['password'] } }));
});

router.post('/', auth, async (req, res) => {
  try {
    const { login, password, name, language } = req.body;
    const user = await User.create({ login, password, name, language });
    res.json({ id: user.id, login, name });
  } catch (e) {
    res.status(400).json({ msg: 'Error' });
  }
});

export default router;
EOFUSERS

cat > backend/src/routes/products.js << 'EOFPROD'
import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const Product = db.models.Product;

function auth(req, res, next) {
  try {
    const token = req.headers?.authorization?.split(' ')[1];
    if (!token) throw new Error();
    jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ msg: 'Not authorized' });
  }
}

router.get('/', auth, async (_, res) => res.json(await Product.findAll()));
router.post('/', auth, async (req, res) => {
  const p = await Product.create(req.body);
  res.json(p);
});

export default router;
EOFPROD

cat > backend/src/routes/clients.js << 'EOFCLI'
import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const Client = db.models.Client;

function auth(req, res, next) {
  try {
    jwt.verify(req.headers?.authorization?.split(' ')[1], process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ msg: 'Not authorized' });
  }
}

router.get('/', auth, async (_, res) => res.json(await Client.findAll()));
router.post('/', auth, async (req, res) => res.json(await Client.create(req.body)));

export default router;
EOFCLI

cat > backend/src/routes/suppliers.js << 'EOFSUP'
import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const Supplier = db.models.Supplier;

function auth(req, res, next) {
  try {
    jwt.verify(req.headers?.authorization?.split(' ')[1], process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ msg: 'Not authorized' });
  }
}

router.get('/', auth, async (_, res) => res.json(await Supplier.findAll()));
router.post('/', auth, async (req, res) => res.json(await Supplier.create(req.body)));

export default router;
EOFSUP

cat > backend/src/seed.js << 'EOFSEED'
import db from './db.js';

(async () => {
  await db.sync({ force: true });
  const User = db.models.User;
  await User.create({ login: 'admin', password: 'admin', name: 'Admin', language: 'uk', isAdmin: true });
  console.log('✅ DB seeded!');
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
EOFSEED

### FRONTEND

cat > frontend/Dockerfile << 'EOFFDOCK'
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOFFDOCK

cat > frontend/package.json << 'EOFFPKG'
{
  "name": "sazhenko-bakery-frontend",
  "version": "1.0.0",
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
    "react-scripts": "^5.0.1"
  }
}
EOFFPKG

cat > frontend/nginx.conf << 'EOFFNGINX'
server {
  listen 80;
  root /usr/share/nginx/html;
  index index.html;
  location / { try_files $uri /index.html; }
}
EOFFNGINX

cat > frontend/public/index.html << 'EOFHTML'
<!DOCTYPE html>
<html lang="uk">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Кондітерські вироби Sazhenko</title>
</head>
<body><div id="root"></div></body>
</html>
EOFHTML

cat > frontend/src/index.js << 'EOFINDEXJS'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import './i18n';

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
EOFINDEXJS

cat > frontend/src/index.css << 'EOFCSS'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea, #764ba2); min-height: 100vh; }
.container { max-width: 1200px; margin: 0 auto; padding: 20px; }
.card { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); margin-bottom: 20px; }
button { padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 5px; }
button.primary { background: #667eea; color: white; }
button.danger { background: #e53e3e; color: white; }
input, select, textarea { width: 100%; padding: 10px; margin: 8px 0; border: 1px solid #ccc; border-radius: 5px; }
.header { background: white; padding: 15px 30px; display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
.logo { display: flex; align-items: center; gap: 15px; }
.logo svg { width: 40px; height: 40px; }
.logo h1 { font-size: 20px; color: #667eea; }
.nav { display: flex; gap: 15px; }
.nav a { text-decoration: none; color: #667eea; font-weight: 600; padding: 8px 15px; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; }
table th, table td { text-align: left; padding: 12px; border-bottom: 1px solid #ddd; }
table th { background: #f7f7f7; }
.login-page { display: flex; justify-content: center; align-items: center; min-height: 100vh; }
.login-card { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 8px 24px rgba(0,0,0,0.2); width: 100%; max-width: 400px; }
.login-card h2 { text-align: center; margin-bottom: 20px; color: #667eea; }
EOFCSS

cat > frontend/src/i18n.js << 'EOFI18N'
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  uk: { translation: { login: 'Логін', password: 'Пароль', signIn: 'Увійти', logout: 'Вихід', products: 'Товари', users: 'Користувачі', clients: 'Клієнти', suppliers: 'Постачальники', name: 'Ім\'я', phone: 'Телефон', description: 'Опис', language: 'Мова', add: 'Додати', code: 'Код' } },
  ru: { translation: { login: 'Логин', password: 'Пароль', signIn: 'Войти', logout: 'Выход', products: 'Товары', users: 'Пользователи', clients: 'Клиенты', suppliers: 'Поставщики', name: 'Имя', phone: 'Телефон', description: 'Описание', language: 'Язык', add: 'Добавить', code: 'Код' } },
  en: { translation: { login: 'Login', password: 'Password', signIn: 'Sign In', logout: 'Logout', products: 'Products', users: 'Users', clients: 'Clients', suppliers: 'Suppliers', name: 'Name', phone: 'Phone', description: 'Description', language: 'Language', add: 'Add', code: 'Code' } }
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'uk',
  fallbackLng: 'en',
  interpolation: { escapeValue: false }
});

export default i18n;
EOFI18N

cat > frontend/src/App.js << 'EOFAPP'
import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoginPage from './pages/LoginPage';
import Dashboard from './pages/Dashboard';
import ProductsPage from './pages/ProductsPage';
import UsersPage from './pages/UsersPage';
import Header from './components/Header';

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const { i18n } = useTranslation();

  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('user') || '{}');
    if (user.language) i18n.changeLanguage(user.language);
  }, [i18n]);

  const handleLogin = (newToken, user) => {
    localStorage.setItem('token', newToken);
    localStorage.setItem('user', JSON.stringify(user));
    setToken(newToken);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken(null);
  };

  if (!token) return <LoginPage onLogin={handleLogin} />;

  return (
    <BrowserRouter>
      <Header onLogout={handleLogout} />
      <div className="container">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/products" element={<ProductsPage />} />
          <Route path="/users" element={<UsersPage />} />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default App;
EOFAPP

cat > frontend/src/pages/LoginPage.js << 'EOFLOGIN'
import React, { useState } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function LoginPage({ onLogin }) {
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const { t, i18n } = useTranslation();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await axios.post('http://localhost:3000/api/auth/login', { login, password });
      onLogin(res.data.token, res.data.user);
      i18n.changeLanguage(res.data.user.language);
    } catch {
      alert('Login failed');
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <h2>🍰 Кондітерські вироби Sazhenko</h2>
        <form onSubmit={handleSubmit}>
          <label>{t('login')}</label>
          <input value={login} onChange={(e) => setLogin(e.target.value)} />
          <label>{t('password')}</label>
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
          <button type="submit" className="primary" style={{ width: '100%' }}>{t('signIn')}</button>
        </form>
        <div style={{ marginTop: 20, textAlign: 'center' }}>
          <select onChange={(e) => i18n.changeLanguage(e.target.value)} value={i18n.language}>
            <option value="uk">Українська</option>
            <option value="ru">Русский</option>
            <option value="en">English</option>
          </select>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
EOFLOGIN

cat > frontend/src/pages/Dashboard.js << 'EOFDASH'
import React from 'react';
function Dashboard() {
  return <div className="card"><h2>🍰 Добро пожаловать</h2><p>Система управління виробництвом</p></div>;
}
export default Dashboard;
EOFDASH

cat > frontend/src/pages/ProductsPage.js << 'EOFPRODPAGE'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [name, setName] = useState('');
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    axios.get('http://localhost:3000/api/products', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setProducts(res.data))
      .catch(console.error);
  }, [token]);

  const handleAdd = () => {
    axios.post('http://localhost:3000/api/products', { name }, { headers: { Authorization: `Bearer ${token}` } })
      .then(res => { setProducts([...products, res.data]); setName(''); })
      .catch(alert);
  };

  return (
    <div className="card">
      <h2>{t('products')}</h2>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder={t('name')} />
      <button className="primary" onClick={handleAdd}>{t('add')}</button>
      <table>
        <thead><tr><th>{t('name')}</th></tr></thead>
        <tbody>
          {products.map(p => <tr key={p.id}><td>{p.name}</td></tr>)}
        </tbody>
      </table>
    </div>
  );
}

export default ProductsPage;
EOFPRODPAGE

cat > frontend/src/pages/UsersPage.js << 'EOFUSERSPAGE'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    axios.get('http://localhost:3000/api/users', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setUsers(res.data))
      .catch(console.error);
  }, [token]);

  return (
    <div className="card">
      <h2>{t('users')}</h2>
      <table>
        <thead><tr><th>{t('login')}</th><th>{t('name')}</th></tr></thead>
        <tbody>
          {users.map(u => <tr key={u.id}><td>{u.login}</td><td>{u.name}</td></tr>)}
        </tbody>
      </table>
    </div>
  );
}

export default UsersPage;
EOFUSERSPAGE

cat > frontend/src/components/Header.js << 'EOFHEADER'
import React from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

function Header({ onLogout }) {
  const { t, i18n } = useTranslation();

  return (
    <div className="header">
      <div className="logo">
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <circle cx="50" cy="50" r="45" fill="#667eea" />
          <path d="M30 60 Q50 30, 70 60" stroke="white" strokeWidth="4" fill="none" />
        </svg>
        <h1>Sazhenko</h1>
      </div>
      <div className="nav">
        <Link to="/">{t('products')}</Link>
        <Link to="/users">{t('users')}</Link>
        <select onChange={(e) => i18n.changeLanguage(e.target.value)} value={i18n.language}>
          <option value="uk">🇺🇦</option>
          <option value="ru">🇷🇺</option>
          <option value="en">🇬🇧</option>
        </select>
        <button className="danger" onClick={onLogout}>{t('logout')}</button>
      </div>
    </div>
  );
}

export default Header;
EOFHEADER

echo "🎉 ВСЕ ФАЙЛЫ СОЗДАНЫ!"
echo ""
echo "Следующие шаги:"
echo "1. docker compose up -d --build"
echo "2. docker compose exec backend npm run db:seed"
echo "3. Откройте http://localhost"
echo ""
echo "Логин: admin / Пароль: admin"
echo ""
