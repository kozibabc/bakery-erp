import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ComponentsPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', price: '', quantity: '', unit: 'кг' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/components', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/components/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); });
    } else {
      axios.post('http://localhost:3000/api/components', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('components')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.price} onChange={e => setForm({...form, price: e.target.value})} placeholder={t('price')} type="number" step="0.01" />
      <input value={form.quantity} onChange={e => setForm({...form, quantity: e.target.value})} placeholder={t('quantity')} type="number" step="0.001" />
      <select value={form.unit} onChange={e => setForm({...form, unit: e.target.value})}>
        <option>кг</option>
        <option>г</option>
        <option>л</option>
        <option>мл</option>
        <option>шт</option>
      </select>
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('price')}</th><th>{t('quantity')}</th><th>Од.</th><th></th></tr></thead>
        <tbody>
          {items.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.price} грн</td>
              <td>{c.quantity}</td>
              <td>{c.unit}</td>
              <td><button className="btn btn-warning" onClick={() => { setForm(c); setEditing(c.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ComponentsPage;
