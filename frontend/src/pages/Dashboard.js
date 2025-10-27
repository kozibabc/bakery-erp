import React from 'react';
import { useTranslation } from 'react-i18next';

function Dashboard() {
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const { t } = useTranslation();
  
  return (
    <div className="card">
      <h2>{t('home')}</h2>
      <p>Вітаємо, {user.name || 'користувач'}!</p>
      <p>✅ Система v3.2 запущена успішно!</p>
      <h3>Нові можливості:</h3>
      <ul>
        <li>📝 Замовлення з генерацією PDF</li>
        <li>📊 Аналітика продажів</li>
        <li>💰 Автоматичне ценообразование</li>
        <li>📋 Розширені рецепти</li>
      </ul>
    </div>
  );
}

export default Dashboard;
