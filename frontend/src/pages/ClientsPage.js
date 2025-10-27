import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import TelegramLink from '../components/TelegramLink';

function ClientsPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/clients', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/clients/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); });
    } else {
      axios.post('http://localhost:3000/api/clients', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('clients')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder={t('phone')} />
      <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder={t('email')} />
      <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder="@username" />
      <select value={form.type} onChange={e => setForm({...form, type: e.target.value})}>
        <option value="wholesale">{t('wholesale')} (+10%)</option>
        <option value="retail1">{t('retail1')} (+40%)</option>
        <option value="retail2">{t('retail2')} (+70%)</option>
      </select>
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('type')}</th><th>{t('phone')}</th><th>Telegram</th><th></th></tr></thead>
        <tbody>
          {items.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{t(c.type)}</td>
              <td>{c.phone}</td>
              <td><TelegramLink username={c.telegram} /></td>
              <td><button className="btn btn-warning" onClick={() => { setForm(c); setEditing(c.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ClientsPage;
