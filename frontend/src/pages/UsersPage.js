import React, { useState, useEffect } from 'react';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState({ 
    login: '', 
    password: '', 
    name: '', 
    email: '', 
    role: 'manager' 
  });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    const res = await fetch('http://localhost:3000/api/users', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setUsers(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const url = editingId 
      ? `http://localhost:3000/api/users/${editingId}`
      : 'http://localhost:3000/api/users';
    const method = editingId ? 'PUT' : 'POST';
    
    const body = { ...form };
    if (editingId && !form.password) {
      delete body.password;
    }
    
    await fetch(url, {
      method,
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(body)
    });
    
    setForm({ login: '', password: '', name: '', email: '', role: 'manager' });
    setEditingId(null);
    setShowForm(false);
    fetchUsers();
  };

  const handleEdit = (user) => {
    setForm({ 
      login: user.login, 
      password: '', 
      name: user.name || '', 
      email: user.email || '', 
      role: user.role 
    });
    setEditingId(user.id);
    setShowForm(true);
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>👤 Користувачі</h2>
          <button className="btn btn-primary" onClick={() => {
            setShowForm(!showForm);
            setEditingId(null);
            setForm({ login: '', password: '', name: '', email: '', role: 'manager' });
          }}>
            {showForm ? 'Скасувати' : '+ Додати користувача'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 15}}>
              <div>
                <label>Логін *</label>
                <input 
                  value={form.login} 
                  onChange={e => setForm({...form, login: e.target.value})} 
                  placeholder="user123"
                  required
                  disabled={editingId}
                />
              </div>
              <div>
                <label>Пароль {editingId ? '(залиште порожнім, щоб не змінювати)' : '*'}</label>
                <input 
                  type="password"
                  value={form.password} 
                  onChange={e => setForm({...form, password: e.target.value})} 
                  placeholder="********"
                  required={!editingId}
                />
              </div>
              <div>
                <label>Ім'я</label>
                <input 
                  value={form.name} 
                  onChange={e => setForm({...form, name: e.target.value})} 
                  placeholder="Іван Петренко"
                />
              </div>
              <div>
                <label>Email</label>
                <input 
                  type="email"
                  value={form.email} 
                  onChange={e => setForm({...form, email: e.target.value})} 
                  placeholder="user@example.com"
                />
              </div>
              <div>
                <label>Роль</label>
                <select 
                  value={form.role} 
                  onChange={e => setForm({...form, role: e.target.value})}
                  style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                >
                  <option value="manager">Менеджер</option>
                  <option value="admin">Адміністратор</option>
                </select>
              </div>
            </div>
            <button type="submit" className="btn btn-primary" style={{marginTop: 15}}>
              {editingId ? 'Оновити' : 'Додати'}
            </button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Логін</th>
              <th style={{padding: 12, textAlign: 'left'}}>Ім'я</th>
              <th style={{padding: 12, textAlign: 'left'}}>Email</th>
              <th style={{padding: 12, textAlign: 'left'}}>Роль</th>
              <th style={{padding: 12, textAlign: 'left'}}>Дія</th>
            </tr>
          </thead>
          <tbody>
            {users.map(user => (
              <tr key={user.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}><strong>{user.login}</strong></td>
                <td style={{padding: 12}}>{user.name || '-'}</td>
                <td style={{padding: 12}}>{user.email || '-'}</td>
                <td style={{padding: 12}}>
                  {user.role === 'admin' && '👑 Адмін'}
                  {user.role === 'manager' && '👔 Менеджер'}
                </td>
                <td style={{padding: 12}}>
                  <button 
                    onClick={() => handleEdit(user)}
                    style={{padding: '5px 15px', background: '#48bb78', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer'}}
                  >
                    ✏️ Редагувати
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {users.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає користувачів
          </p>
        )}
      </div>
    </div>
  );
}

export default UsersPage;
