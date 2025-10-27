import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom';
import ClientsPage from './pages/ClientsPage';
import SuppliersPage from './pages/SuppliersPage';
import ComponentsPage from './pages/ComponentsPage';
import PurchasesPage from './pages/PurchasesPage';
import StockPage from './pages/StockPage';
import ProductsPage from './pages/ProductsPage';
import RecipesPage from './pages/RecipesPage';
import OrdersPage from './pages/OrdersPage';
import UsersPage from './pages/UsersPage';
import AnalyticsPage from './pages/AnalyticsPage';

function Login({ onLogin }) {
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
      if (data.token) onLogin(data.token);
      else alert('Помилка входу');
    } catch { alert('Помилка підключення'); }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <h2 style={{textAlign: 'center', marginBottom: 20}}>🍰 Bakery ERP v4.1</h2>
        <form onSubmit={handleSubmit}>
          <input value={login} onChange={e => setLogin(e.target.value)} placeholder="Логін" />
          <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Пароль" />
          <button type="submit" className="btn btn-primary" style={{width: '100%'}}>Увійти</button>
        </form>
      </div>
    </div>
  );
}

function Dashboard() {
  return (
    <div className="card">
      <h2>🏠 Головна</h2>
      <p>Вітаємо в Bakery ERP v4.1 ADVANCED!</p>
      <h3 style={{marginTop: 20}}>✅ Повний функціонал:</h3>
      <ul style={{marginTop: 10, lineHeight: 2}}>
        <li>✅ Персистентне зберігання</li>
        <li>✅ Компоненти з типами</li>
        <li>✅ Рецепти з компонентами</li>
        <li>✅ Закупки → Склад (автооновлення)</li>
        <li>✅ Замовлення з товарами</li>
        <li>✅ Виконання замовлень</li>
        <li>✅ Користувачі</li>
        <li>✅ Аналітика</li>
      </ul>
    </div>
  );
}

function ComingSoon({ title }) {
  return (
    <div className="card">
      <h2>{title}</h2>
      <p>Сторінка в розробці.</p>
    </div>
  );
}

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));

  const handleLogin = (newToken) => {
    localStorage.setItem('token', newToken);
    setToken(newToken);
  };

  const handleLogout = () => {
    localStorage.clear();
    setToken(null);
  };

  if (!token) return <Login onLogin={handleLogin} />;

  const navStyle = ({ isActive }) => ({
    display: 'block',
    color: 'white',
    textDecoration: 'none',
    padding: '10px',
    margin: '5px 0',
    borderRadius: '5px',
    background: isActive ? 'rgba(255,255,255,0.2)' : 'transparent'
  });

  return (
    <BrowserRouter>
      <div className="app">
        <div className="sidebar">
          <h1>🍰 Sazhenko</h1>
          <nav>
            <NavLink to="/" end style={navStyle}>🏠 Головна</NavLink>
            <NavLink to="/purchases" style={navStyle}>📦 Закупки</NavLink>
            <NavLink to="/stock" style={navStyle}>📊 Склад</NavLink>
            <NavLink to="/components" style={navStyle}>🧩 Компоненти</NavLink>
            <NavLink to="/recipes" style={navStyle}>📋 Рецепти</NavLink>
            <NavLink to="/products" style={navStyle}>🍰 Товари</NavLink>
            <NavLink to="/orders" style={navStyle}>📝 Замовлення</NavLink>
            <NavLink to="/clients" style={navStyle}>👥 Клієнти</NavLink>
            <NavLink to="/suppliers" style={navStyle}>🚚 Постачальники</NavLink>
            <NavLink to="/users" style={navStyle}>👤 Користувачі</NavLink>
            <NavLink to="/analytics" style={navStyle}>📊 Аналітика</NavLink>
            <NavLink to="/settings" style={navStyle}>⚙️ Налаштування</NavLink>
          </nav>
          <button 
            className="btn" 
            onClick={handleLogout} 
            style={{
              marginTop: 'auto',
              width: '100%',
              background: 'rgba(255,255,255,0.2)',
              color: 'white'
            }}
          >
            🚪 Вихід
          </button>
        </div>
        <div className="main">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/purchases" element={<PurchasesPage />} />
            <Route path="/stock" element={<StockPage />} />
            <Route path="/components" element={<ComponentsPage />} />
            <Route path="/recipes" element={<RecipesPage />} />
            <Route path="/products" element={<ProductsPage />} />
            <Route path="/orders" element={<OrdersPage />} />
            <Route path="/clients" element={<ClientsPage />} />
            <Route path="/suppliers" element={<SuppliersPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/settings" element={<ComingSoon title="⚙️ Налаштування" />} />
          </Routes>
        </div>
      </div>
    </BrowserRouter>
  );
}

export default App;
