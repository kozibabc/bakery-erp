import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import TelegramLink from '../components/TelegramLink';

function SuppliersPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/suppliers', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/suppliers/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '' }); });
    } else {
      axios.post('http://localhost:3000/api/suppliers', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', phone: '', email: '', telegram: '' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('suppliers')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder={t('phone')} />
      <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder={t('email')} />
      <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder="@username" />
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('phone')}</th><th>{t('email')}</th><th>Telegram</th><th></th></tr></thead>
        <tbody>
          {items.map(s => (
            <tr key={s.id}>
              <td>{s.name}</td>
              <td>{s.phone}</td>
              <td>{s.email}</td>
              <td><TelegramLink username={s.telegram} /></td>
              <td><button className="btn btn-warning" onClick={() => { setForm(s); setEditing(s.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default SuppliersPage;
