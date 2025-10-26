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
