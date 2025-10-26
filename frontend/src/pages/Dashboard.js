import React from 'react';
import { useTranslation } from 'react-i18next';

function Dashboard() {
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const { t } = useTranslation();
  
  return (
    <div className="card">
      <h2>{t('home')}</h2>
      <p>Вітаємо, {user.name || 'користувач'}!</p>
      <p>✅ Система v3.1 запущена успішно!</p>
    </div>
  );
}

export default Dashboard;
