import React, { useState, useEffect } from 'react';

function AnalyticsPage() {
  const [stats, setStats] = useState({
    totalOrders: 0,
    doneOrders: 0,
    draftOrders: 0,
    totalClients: 0,
    totalProducts: 0,
    stockValue: 0
  });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    try {
      const [orders, clients, products, stock] = await Promise.all([
        fetch('http://localhost:3000/api/orders', { headers: { Authorization: `Bearer ${token}` } }).then(r => r.json()),
        fetch('http://localhost:3000/api/clients', { headers: { Authorization: `Bearer ${token}` } }).then(r => r.json()),
        fetch('http://localhost:3000/api/products', { headers: { Authorization: `Bearer ${token}` } }).then(r => r.json()),
        fetch('http://localhost:3000/api/stock', { headers: { Authorization: `Bearer ${token}` } }).then(r => r.json())
      ]);

      const stockValue = stock.reduce((sum, item) => 
        sum + (parseFloat(item.qtyOnHand) * parseFloat(item.avgCost)), 0
      );

      setStats({
        totalOrders: orders.length,
        doneOrders: orders.filter(o => o.status === 'done').length,
        draftOrders: orders.filter(o => o.status === 'draft').length,
        totalClients: clients.length,
        totalProducts: products.length,
        stockValue
      });
    } catch (error) {
      console.error('Error fetching analytics:', error);
    }
  };

  const StatCard = ({ icon, title, value, color }) => (
    <div style={{
      background: 'white',
      padding: 20,
      borderRadius: 8,
      boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
      borderLeft: `4px solid ${color}`
    }}>
      <div style={{fontSize: 40, marginBottom: 10}}>{icon}</div>
      <div style={{color: '#666', fontSize: 14, marginBottom: 5}}>{title}</div>
      <div style={{fontSize: 28, fontWeight: 'bold', color}}>{value}</div>
    </div>
  );

  return (
    <div>
      <div className="card">
        <h2>📊 Аналітика</h2>
        <p style={{color: '#666', marginTop: 10}}>
          Загальна статистика системи
        </p>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 20,
        marginTop: 20
      }}>
        <StatCard 
          icon="📝" 
          title="Всього замовлень" 
          value={stats.totalOrders} 
          color="#667eea" 
        />
        <StatCard 
          icon="✅" 
          title="Виконано" 
          value={stats.doneOrders} 
          color="#48bb78" 
        />
        <StatCard 
          icon="📋" 
          title="Чернеток" 
          value={stats.draftOrders} 
          color="#ed8936" 
        />
        <StatCard 
          icon="👥" 
          title="Клієнтів" 
          value={stats.totalClients} 
          color="#4299e1" 
        />
        <StatCard 
          icon="🍰" 
          title="Товарів" 
          value={stats.totalProducts} 
          color="#9f7aea" 
        />
        <StatCard 
          icon="💰" 
          title="Вартість складу" 
          value={`${stats.stockValue.toFixed(0)} грн`} 
          color="#f56565" 
        />
      </div>
    </div>
  );
}

export default AnalyticsPage;
