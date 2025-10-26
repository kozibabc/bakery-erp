import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoginPage from './pages/LoginPage';
import Dashboard from './pages/Dashboard';
import ProductsPage from './pages/ProductsPage';
import UsersPage from './pages/UsersPage';
import Sidebar from './components/Sidebar';

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
    i18n.changeLanguage(user.language);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken(null);
  };

  if (!token) return <LoginPage onLogin={handleLogin} />;

  return (
    <BrowserRouter>
      <div className="app-container">
        <Sidebar onLogout={handleLogout} />
        <div className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/products" element={<ProductsPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </div>
      </div>
    </BrowserRouter>
  );
}

export default App;
