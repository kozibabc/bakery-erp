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
