#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP v3.2 - Part 4 (Final Pages)
# Запустите ПОСЛЕ Part 1, 2, 3
###############################################################################

set -e

echo "🍰 Bakery ERP v3.2 - Final Pages (Part 4)"
echo "=========================================="
echo ""

cat > frontend/src/pages/RecipesPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function RecipesPage() {
  const [recipes, setRecipes] = useState([]);
  const [components, setComponents] = useState([]);
  const [form, setForm] = useState({ name: '', outputWeight: 1, outputUnit: 'кг', items: [] });
  const [showModal, setShowModal] = useState(false);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadData();
    axios.get('http://localhost:3000/api/components', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setComponents(res.data));
  }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/recipes', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setRecipes(res.data));
  };

  const addItem = () => {
    setForm({...form, items: [...form.items, { componentId: '', weight: '', unit: 'кг' }]});
  };

  const updateItem = (idx, field, value) => {
    const items = [...form.items];
    items[idx][field] = value;
    setForm({...form, items});
  };

  const handleSubmit = () => {
    axios.post('http://localhost:3000/api/recipes', form, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => { loadData(); setForm({ name: '', outputWeight: 1, outputUnit: 'кг', items: [] }); setShowModal(false); });
  };

  return (
    <div className="card">
      <h2>{t('recipes')}</h2>
      <button className="btn btn-primary" onClick={() => setShowModal(true)}>{t('add')}</button>
      <table>
        <thead><tr><th>{t('name')}</th><th>Вихід</th></tr></thead>
        <tbody>
          {recipes.map(r => <tr key={r.id}><td>{r.name}</td><td>{r.outputWeight} {r.outputUnit}</td></tr>)}
        </tbody>
      </table>

      {showModal && (
        <div className="modal">
          <div className="modal-content">
            <h3>Новий рецепт</h3>
            <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
            <div style={{display: 'flex', gap: 10}}>
              <input value={form.outputWeight} onChange={e => setForm({...form, outputWeight: e.target.value})} placeholder="Вихід" type="number" step="0.01" />
              <select value={form.outputUnit} onChange={e => setForm({...form, outputUnit: e.target.value})}>
                <option>кг</option>
                <option>г</option>
                <option>л</option>
                <option>мл</option>
              </select>
            </div>
            <h4>Склад:</h4>
            {form.items.map((item, idx) => (
              <div key={idx} style={{display: 'flex', gap: 10, marginBottom: 10}}>
                <select value={item.componentId} onChange={e => updateItem(idx, 'componentId', e.target.value)}>
                  <option value="">Оберіть компонент</option>
                  {components.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
                <input value={item.weight} onChange={e => updateItem(idx, 'weight', e.target.value)} placeholder="Кількість" type="number" step="0.001" />
                <select value={item.unit} onChange={e => updateItem(idx, 'unit', e.target.value)}>
                  <option>кг</option>
                  <option>г</option>
                  <option>л</option>
                  <option>мл</option>
                </select>
              </div>
            ))}
            <button className="btn btn-success" onClick={addItem}>+ Компонент</button>
            <div style={{marginTop: 20}}>
              <button className="btn btn-primary" onClick={handleSubmit}>{t('save')}</button>
              <button className="btn" onClick={() => { setShowModal(false); setForm({ name: '', outputWeight: 1, outputUnit: 'кг', items: [] }); }}>{t('cancel')}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default RecipesPage;
EOF

cat > frontend/src/pages/OrdersPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [clients, setClients] = useState([]);
  const [products, setProducts] = useState([]);
  const [form, setForm] = useState({ clientId: '', items: [], notes: '' });
  const [showModal, setShowModal] = useState(false);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadData();
    axios.get('http://localhost:3000/api/clients', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setClients(res.data));
    axios.get('http://localhost:3000/api/products', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setProducts(res.data));
  }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/orders', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setOrders(res.data));
  };

  const addItem = () => {
    setForm({...form, items: [...form.items, { productId: '', boxes: 1 }]});
  };

  const updateItem = (idx, field, value) => {
    const items = [...form.items];
    items[idx][field] = value;
    setForm({...form, items});
  };

  const handleSubmit = () => {
    axios.post('http://localhost:3000/api/orders', form, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => { loadData(); setForm({ clientId: '', items: [], notes: '' }); setShowModal(false); });
  };

  const downloadOrderPDF = (orderId) => {
    window.open(`http://localhost:3000/api/orders/${orderId}/pdf`, '_blank');
  };

  const changeStatus = (orderId, status) => {
    axios.put(`http://localhost:3000/api/orders/${orderId}/status`, { status }, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => loadData());
  };

  return (
    <div className="card">
      <h2>{t('orders')}</h2>
      <button className="btn btn-primary" onClick={() => setShowModal(true)}>{t('add')}</button>
      <table>
        <thead><tr><th>ID</th><th>Клієнт</th><th>Коробок</th><th>Сума</th><th>Статус</th><th></th></tr></thead>
        <tbody>
          {orders.map(o => (
            <tr key={o.id}>
              <td>{o.id}</td>
              <td>{o.Client?.name}</td>
              <td>{o.totalBoxes}</td>
              <td>{o.totalPrice} грн</td>
              <td>{o.status}</td>
              <td>
                <button className="btn btn-success" onClick={() => downloadOrderPDF(o.id)}>PDF</button>
                {o.status === 'open' && <button className="btn btn-warning" onClick={() => changeStatus(o.id, 'completed')}>Виконано</button>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {showModal && (
        <div className="modal">
          <div className="modal-content">
            <h3>Новий заказ</h3>
            <select value={form.clientId} onChange={e => setForm({...form, clientId: e.target.value})}>
              <option value="">Оберіть клієнта</option>
              {clients.map(c => <option key={c.id} value={c.id}>{c.name} ({t(c.type)})</option>)}
            </select>
            <h4>Товари:</h4>
            {form.items.map((item, idx) => (
              <div key={idx} style={{display: 'flex', gap: 10, marginBottom: 10}}>
                <select value={item.productId} onChange={e => updateItem(idx, 'productId', e.target.value)}>
                  <option value="">Оберіть товар</option>
                  {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
                <input value={item.boxes} onChange={e => updateItem(idx, 'boxes', e.target.value)} placeholder="Коробок" type="number" />
              </div>
            ))}
            <button className="btn btn-success" onClick={addItem}>+ Товар</button>
            <textarea value={form.notes} onChange={e => setForm({...form, notes: e.target.value})} placeholder="Примітки" rows={3}></textarea>
            <div style={{marginTop: 20}}>
              <button className="btn btn-primary" onClick={handleSubmit}>{t('save')}</button>
              <button className="btn" onClick={() => { setShowModal(false); setForm({ clientId: '', items: [], notes: '' }); }}>{t('cancel')}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default OrdersPage;
EOF

cat > frontend/src/pages/AnalyticsPage.js << 'EOF'
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
EOF

cat > frontend/src/pages/SettingsPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function SettingsPage() {
  const [settings, setSettings] = useState({ wholesaleMarkup: 10, retail1Markup: 40, retail2Markup: 70 });
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    axios.get('http://localhost:3000/api/settings', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setSettings(res.data));
  }, []);

  const handleSave = () => {
    axios.put('http://localhost:3000/api/settings', settings, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => alert('Збережено!'));
  };

  return (
    <div className="card">
      <h2>{t('settings')}</h2>
      <div className="form-group">
        <label>{t('wholesale')} {t('markup')} (%)</label>
        <input value={settings.wholesaleMarkup} onChange={e => setSettings({...settings, wholesaleMarkup: e.target.value})} type="number" />
      </div>
      <div className="form-group">
        <label>{t('retail1')} {t('markup')} (%)</label>
        <input value={settings.retail1Markup} onChange={e => setSettings({...settings, retail1Markup: e.target.value})} type="number" />
      </div>
      <div className="form-group">
        <label>{t('retail2')} {t('markup')} (%)</label>
        <input value={settings.retail2Markup} onChange={e => setSettings({...settings, retail2Markup: e.target.value})} type="number" />
      </div>
      <button className="btn btn-primary" onClick={handleSave}>{t('save')}</button>
    </div>
  );
}

export default SettingsPage;
EOF

echo ""
echo "✅ Все 4 части v3.2 созданы!"
echo ""
echo "🚀 Запуск:"
echo "  chmod +x install-v3.2-part*.sh"
echo "  ./install-v3.2-part1.sh"
echo "  ./install-v3.2-part2.sh"
echo "  ./install-v3.2-part3.sh"
echo "  ./install-v3.2-part4.sh"
echo "  docker compose down --volumes"
echo "  docker compose up -d --build"
echo ""
echo "🔐 admin / admin"
echo "📍 http://localhost"
echo ""
