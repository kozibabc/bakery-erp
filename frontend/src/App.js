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
