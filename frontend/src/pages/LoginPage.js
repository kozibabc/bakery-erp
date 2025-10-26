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
