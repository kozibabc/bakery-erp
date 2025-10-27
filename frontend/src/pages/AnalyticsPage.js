import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function AnalyticsPage() {
  const [summary, setSummary] = useState({ totalOrders: 0, openOrders: 0, completedOrders: 0, totalRevenue: 0 });
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadSummary();
  }, []);

  const loadSummary = () => {
    const params = new URLSearchParams();
    if (startDate) params.append('startDate', startDate);
    if (endDate) params.append('endDate', endDate);
    
    axios.get(`http://localhost:3000/api/analytics/summary?${params}`, { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setSummary(res.data));
  };

  return (
    <div className="card">
      <h2>{t('analytics')}</h2>
      <div style={{marginBottom: 20}}>
        <label>Період:</label>
        <div style={{display: 'flex', gap: 10}}>
          <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
          <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
          <button className="btn btn-primary" onClick={loadSummary}>Оновити</button>
        </div>
      </div>
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 20}}>
        <div style={{background: '#667eea', color: 'white', padding: 20, borderRadius: 8}}>
          <h3>Всього замовлень</h3>
          <p style={{fontSize: 32, fontWeight: 'bold'}}>{summary.totalOrders}</p>
        </div>
        <div style={{background: '#48bb78', color: 'white', padding: 20, borderRadius: 8}}>
          <h3>Відкриті</h3>
          <p style={{fontSize: 32, fontWeight: 'bold'}}>{summary.openOrders}</p>
        </div>
        <div style={{background: '#ed8936', color: 'white', padding: 20, borderRadius: 8}}>
          <h3>Виконані</h3>
          <p style={{fontSize: 32, fontWeight: 'bold'}}>{summary.completedOrders}</p>
        </div>
        <div style={{background: '#9f7aea', color: 'white', padding: 20, borderRadius: 8}}>
          <h3>Виторг</h3>
          <p style={{fontSize: 32, fontWeight: 'bold'}}>{summary.totalRevenue} грн</p>
        </div>
      </div>
    </div>
  );
}

export default AnalyticsPage;
