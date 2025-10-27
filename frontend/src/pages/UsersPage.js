import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import TelegramLink from '../components/TelegramLink';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState({ login: '', password: '', name: '', email: '', phone: '', telegram: '' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadUsers(); }, []);

  const loadUsers = () => {
    axios.get('http://localhost:3000/api/users', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setUsers(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/users/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadUsers(); setEditing(null); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); });
    } else {
      axios.post('http://localhost:3000/api/users', { ...form, role: 'manager' }, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadUsers(); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); });
    }
  };

  const handleEdit = (user) => {
    setForm({ login: user.login, password: '', name: user.name, email: user.email || '', phone: user.phone || '', telegram: user.telegram || '' });
    setEditing(user.id);
  };

  return (
    <div className="card">
      <h2>{t('users')}</h2>
      <div className="form-group">
        <label>{t('login')}</label>
        <input value={form.login} onChange={e => setForm({...form, login: e.target.value})} disabled={editing} />
      </div>
      <div className="form-group">
        <label>{t('password')}</label>
        <input type="password" value={form.password} onChange={e => setForm({...form, password: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('name')}</label>
        <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('email')}</label>
        <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('phone')}</label>
        <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('telegram')}</label>
        <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder="@username" />
      </div>
      <button className="btn btn-primary" onClick={handleSubmit}>
        {editing ? t('save') : t('add')}
      </button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('login')}</th><th>{t('name')}</th><th>{t('email')}</th><th>{t('phone')}</th><th>Telegram</th><th></th></tr></thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.login}</td>
              <td>{u.name}</td>
              <td>{u.email}</td>
              <td>{u.phone}</td>
              <td><TelegramLink username={u.telegram} /></td>
              <td><button className="btn btn-warning" onClick={() => handleEdit(u)}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default UsersPage;
