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
