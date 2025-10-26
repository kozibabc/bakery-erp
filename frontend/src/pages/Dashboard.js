import React from 'react';
import { useTranslation } from 'react-i18next';

function Dashboard() {
  const { t, i18n } = useTranslation();

  // Моковые данные для демонстрации
  const stats = {
    orders: 2,
    inProgress: 1,
    products: 2,
    recipes: 3
  };

  const orders = [
    { id: 'ORD-2025-001', client: 'Супермаркет Продукти №1', date: '25.10.2025', status: 'ПІДТВЕРДЖЕН', amount: '21 000,00 грн₴' },
    { id: 'ORD-2025-002', client: 'Кафе Сладкий рай', date: '26.10.2025', status: 'ЧЕРНОВИК', amount: '5 760,00 грн₴' }
  ];

  return (
    <div>
      <div className="header">
        <h2>🍰 Добро пожаловать</h2>
        <div className="header-actions">
          <select 
            className="lang-selector" 
            onChange={(e) => i18n.changeLanguage(e.target.value)} 
            value={i18n.language}
          >
            <option value="uk">🇺🇦 UA</option>
            <option value="ru">🇷🇺 RU</option>
            <option value="en">🇬🇧 EN</option>
          </select>
        </div>
      </div>

      <div className="stats-grid">
        <div className="stat-card blue">
          <div className="stat-label">Всего заказов</div>
          <div className="stat-value">{stats.orders}</div>
        </div>
        <div className="stat-card green">
          <div className="stat-label">Заказы в работе</div>
          <div className="stat-value">{stats.inProgress}</div>
        </div>
        <div className="stat-card orange">
          <div className="stat-label">Товаров в каталоге</div>
          <div className="stat-value">{stats.products}</div>
        </div>
        <div className="stat-card purple">
          <div className="stat-label">Рецептов</div>
          <div className="stat-value">{stats.recipes}</div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <h3 className="card-title">Панель управления</h3>
        </div>
        <table>
          <thead>
            <tr>
              <th>Номер заказа</th>
              <th>Клиент</th>
              <th>Дата доставки</th>
              <th>Статус</th>
              <th>Сумма</th>
            </tr>
          </thead>
          <tbody>
            {orders.map(order => (
              <tr key={order.id}>
                <td>{order.id}</td>
                <td>{order.client}</td>
                <td>{order.date}</td>
                <td>
                  <span className={`status-badge ${order.status === 'ПІДТВЕРДЖЕН' ? 'confirmed' : 'draft'}`}>
                    {order.status}
                  </span>
                </td>
                <td>{order.amount}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Dashboard;
