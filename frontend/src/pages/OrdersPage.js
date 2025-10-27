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
