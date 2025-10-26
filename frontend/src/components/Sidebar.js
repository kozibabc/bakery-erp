import React from 'react';
import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

function Sidebar({ onLogout }) {
  const { t } = useTranslation();
  const user = JSON.parse(localStorage.getItem('user') || '{}');

  return (
    <div className="sidebar">
      <div className="sidebar-logo">
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <circle cx="50" cy="50" r="45" fill="white" opacity="0.2" />
          <path d="M30 60 Q50 30, 70 60" stroke="white" strokeWidth="4" fill="none" />
        </svg>
        <h1>Sazhenko</h1>
      </div>

      <nav className="sidebar-nav">
        <NavLink to="/" end>🏠 Головна</NavLink>
        <NavLink to="/products">🍰 {t('products')}</NavLink>
        <NavLink to="/clients">👥 {t('clients')}</NavLink>
        <NavLink to="/suppliers">🚚 {t('suppliers')}</NavLink>
        <NavLink to="/orders">📦 Закази</NavLink>
        <NavLink to="/recipes">📋 Рецепти</NavLink>
        <NavLink to="/users">👤 {t('users')}</NavLink>
      </nav>

      <div className="sidebar-footer">
        <div className="user-info">
          <div className="user-avatar">{user.name?.[0] || 'A'}</div>
          <div>
            <div style={{ fontWeight: 600 }}>{user.name || 'Admin'}</div>
            <div style={{ fontSize: '12px', opacity: 0.8 }}>{user.login}</div>
          </div>
        </div>
        <button className="logout-btn" onClick={onLogout}>
          {t('logout')}
        </button>
      </div>
    </div>
  );
}

export default Sidebar;
