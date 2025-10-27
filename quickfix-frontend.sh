#!/bin/bash

###############################################################################
# Bakery ERP v4.0 - QUICKFIX для frontend
# Создаёт недостающие файлы frontend
###############################################################################

set -e

echo "🔧 v4.0 QUICKFIX - Создаю frontend..."
echo ""

# Проверяем наличие директорий
if [ ! -d "frontend" ]; then
  mkdir -p frontend/src/{pages,components,i18n} frontend/public
fi

# ============================================================================
# FRONTEND DOCKERFILE
# ============================================================================

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

cat > frontend/nginx.conf << 'EOF'
server {
  listen 80;
  root /usr/share/nginx/html;
  index index.html;
  location / {
    try_files $uri /index.html;
  }
  location /api {
    proxy_pass http://backend:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
EOF

cat > frontend/package.json << 'EOF'
{
  "name": "bakery-frontend",
  "version": "4.0.0",
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
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  }
}
EOF

cat > frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="uk">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Bakery ERP v4.0</title>
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
import App from './App';

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
EOF

cat > frontend/src/index.css << 'EOF'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif; 
  background: #f5f7fa; 
}
.app { display: flex; min-height: 100vh; }
.sidebar { 
  width: 250px; 
  background: linear-gradient(180deg, #667eea 0%, #764ba2 100%); 
  color: white; 
  padding: 20px; 
  display: flex; 
  flex-direction: column; 
}
.sidebar h1 { font-size: 20px; margin-bottom: 30px; }
.sidebar nav a { 
  display: block; 
  color: white; 
  text-decoration: none; 
  padding: 10px; 
  margin: 5px 0; 
  border-radius: 5px; 
}
.sidebar nav a:hover, .sidebar nav a.active { background: rgba(255,255,255,0.2); }
.main { flex: 1; padding: 30px; overflow-y: auto; }
.card { 
  background: white; 
  padding: 20px; 
  border-radius: 8px; 
  box-shadow: 0 2px 4px rgba(0,0,0,0.1); 
  margin-bottom: 20px; 
}
.form-group { margin-bottom: 15px; }
.form-group label { display: block; margin-bottom: 5px; font-weight: 500; }
input, select, textarea { 
  width: 100%; 
  padding: 10px; 
  border: 1px solid #ddd; 
  border-radius: 5px; 
  font-size: 14px;
}
.btn { 
  padding: 10px 20px; 
  border: none; 
  border-radius: 5px; 
  cursor: pointer; 
  font-weight: 500; 
  margin-right: 10px; 
  margin-top: 10px;
}
.btn-primary { background: #667eea; color: white; }
.btn-success { background: #48bb78; color: white; }
.btn-warning { background: #ed8936; color: white; }
.btn-danger { background: #f56565; color: white; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; }
table th { 
  background: #f7fafc; 
  padding: 12px; 
  text-align: left; 
  border-bottom: 2px solid #e2e8f0; 
  font-weight: 600;
}
table td { padding: 12px; border-bottom: 1px solid #e2e8f0; }
.login-page { 
  min-height: 100vh; 
  display: flex; 
  align-items: center; 
  justify-content: center; 
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
}
.login-card { 
  background: white; 
  padding: 40px; 
  border-radius: 12px; 
  width: 400px; 
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
}
.modal { 
  position: fixed; 
  top: 0; 
  left: 0; 
  width: 100%; 
  height: 100%; 
  background: rgba(0,0,0,0.5); 
  display: flex; 
  align-items: center; 
  justify-content: center; 
  z-index: 1000; 
}
.modal-content { 
  background: white; 
  padding: 30px; 
  border-radius: 12px; 
  width: 600px; 
  max-height: 80vh; 
  overflow-y: auto; 
}
.telegram-link { color: #0088cc; text-decoration: none; }
.telegram-link:hover { text-decoration: underline; }
EOF

cat > frontend/src/App.js << 'EOF'
import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate, NavLink } from 'react-router-dom';

function LoginPage({ onLogin }) {
  const [login, setLogin] = useState('admin');
  const [password, setPassword] = useState('admin');

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch('http://localhost:3000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ login, password })
      });
      const data = await res.json();
      if (data.token) {
        onLogin(data.token, data.user);
      } else {
        alert('Помилка входу');
      }
    } catch (err) {
      alert('Помилка з\'єднання');
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <h2 style={{textAlign: 'center', marginBottom: 20}}>🍰 Bakery ERP v4.0</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <input value={login} onChange={e => setLogin(e.target.value)} placeholder="Логін" />
          </div>
          <div className="form-group">
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Пароль" />
          </div>
          <button type="submit" className="btn btn-primary" style={{width: '100%'}}>Увійти</button>
        </form>
      </div>
    </div>
  );
}

function Dashboard() {
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  return (
    <div className="card">
      <h2>🏠 Головна</h2>
      <p>Вітаємо, {user.name || 'користувач'}!</p>
      <h3>Система v4.0 запущена</h3>
      <ul style={{marginTop: 20, lineHeight: 2}}>
        <li>✅ Персистентне зберігання даних</li>
        <li>✅ Модуль закупок</li>
        <li>✅ Склад з автоматичним розрахунком</li>
        <li>✅ Списання при запуску виробництва</li>
        <li>✅ Розрахунок собівартості</li>
        <li>✅ PDF та Excel прайси</li>
      </ul>
    </div>
  );
}

function ComingSoonPage({ title }) {
  return (
    <div className="card">
      <h2>{title}</h2>
      <p>Сторінка в розробці. Функціонал буде додано найближчим часом.</p>
    </div>
  );
}

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));

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
            <NavLink to="/" end>🏠 Головна</NavLink>
            <NavLink to="/purchases">📦 Закупки</NavLink>
            <NavLink to="/stock">📊 Склад</NavLink>
            <NavLink to="/components">🧩 Компоненти</NavLink>
            <NavLink to="/recipes">📋 Рецепти</NavLink>
            <NavLink to="/products">🍰 Товари</NavLink>
            <NavLink to="/orders">📝 Замовлення</NavLink>
            <NavLink to="/clients">👥 Клієнти</NavLink>
            <NavLink to="/suppliers">🚚 Постачальники</NavLink>
            <NavLink to="/analytics">📊 Аналітика</NavLink>
            <NavLink to="/settings">⚙️ Налаштування</NavLink>
          </nav>
          <button 
            className="btn btn-danger" 
            onClick={handleLogout} 
            style={{marginTop: 'auto', width: '100%'}}
          >
            Вихід
          </button>
        </div>
        <div className="main">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/purchases" element={<ComingSoonPage title="📦 Закупки" />} />
            <Route path="/stock" element={<ComingSoonPage title="📊 Склад" />} />
            <Route path="/components" element={<ComingSoonPage title="🧩 Компоненти" />} />
            <Route path="/recipes" element={<ComingSoonPage title="📋 Рецепти" />} />
            <Route path="/products" element={<ComingSoonPage title="🍰 Товари" />} />
            <Route path="/orders" element={<ComingSoonPage title="📝 Замовлення" />} />
            <Route path="/clients" element={<ComingSoonPage title="👥 Клієнти" />} />
            <Route path="/suppliers" element={<ComingSoonPage title="🚚 Постачальники" />} />
            <Route path="/analytics" element={<ComingSoonPage title="📊 Аналітика" />} />
            <Route path="/settings" element={<ComingSoonPage title="⚙️ Налаштування" />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </div>
      </div>
    </BrowserRouter>
  );
}

export default App;
EOF

echo ""
echo "✅ Frontend файлы созданы!"
echo ""
echo "🚀 Теперь запустите:"
echo "   docker compose up -d --build"
echo ""
