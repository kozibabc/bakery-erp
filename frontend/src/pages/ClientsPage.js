import React, { useState, useEffect } from 'react';

function ClientsPage() {
  const [clients, setClients] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '', type: 'wholesale', notes: '' });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    const res = await fetch('http://localhost:3000/api/clients', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setClients(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const url = editingId 
      ? `http://localhost:3000/api/clients/${editingId}`
      : 'http://localhost:3000/api/clients';
    const method = editingId ? 'PUT' : 'POST';
    
    await fetch(url, {
      method,
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(form)
    });
    
    setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale', notes: '' });
    setEditingId(null);
    setShowForm(false);
    fetchClients();
  };

  const handleEdit = (client) => {
    setForm(client);
    setEditingId(client.id);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Видалити клієнта?')) return;
    await fetch(`http://localhost:3000/api/clients/${id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    });
    fetchClients();
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>👥 Клієнти</h2>
          <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
            {showForm ? 'Скасувати' : '+ Додати клієнта'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{marginBottom: 15}}>
              <label>Назва *</label>
              <input 
                value={form.name} 
                onChange={e => setForm({...form, name: e.target.value})} 
                placeholder="ТОВ 'Кафе Смак'"
                required
              />
            </div>
            <div style={{marginBottom: 15}}>
              <label>Телефон</label>
              <input 
                value={form.phone} 
                onChange={e => setForm({...form, phone: e.target.value})} 
                placeholder="+380501234567"
              />
            </div>
            <div style={{marginBottom: 15}}>
              <label>Email</label>
              <input 
                type="email"
                value={form.email} 
                onChange={e => setForm({...form, email: e.target.value})} 
                placeholder="client@example.com"
              />
            </div>
            <div style={{marginBottom: 15}}>
              <label>Telegram</label>
              <input 
                value={form.telegram} 
                onChange={e => setForm({...form, telegram: e.target.value})} 
                placeholder="@username"
              />
            </div>
            <div style={{marginBottom: 15}}>
              <label>Тип клієнта</label>
              <select 
                value={form.type} 
                onChange={e => setForm({...form, type: e.target.value})}
                style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
              >
                <option value="wholesale">Опт</option>
                <option value="retail1">Роздріб 1</option>
                <option value="retail2">Роздріб 2</option>
              </select>
            </div>
            <div style={{marginBottom: 15}}>
              <label>Примітки</label>
              <textarea 
                value={form.notes} 
                onChange={e => setForm({...form, notes: e.target.value})} 
                rows={3}
                style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                placeholder="Додаткова інформація"
              />
            </div>
            <button type="submit" className="btn btn-primary">
              {editingId ? 'Оновити' : 'Додати'}
            </button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Назва</th>
              <th style={{padding: 12, textAlign: 'left'}}>Телефон</th>
              <th style={{padding: 12, textAlign: 'left'}}>Тип</th>
              <th style={{padding: 12, textAlign: 'left'}}>Email</th>
              <th style={{padding: 12, textAlign: 'left'}}>Дії</th>
            </tr>
          </thead>
          <tbody>
            {clients.map(client => (
              <tr key={client.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{client.name}</td>
                <td style={{padding: 12}}>{client.phone || '-'}</td>
                <td style={{padding: 12}}>
                  {client.type === 'wholesale' && '🏢 Опт'}
                  {client.type === 'retail1' && '🛒 Роздріб 1'}
                  {client.type === 'retail2' && '🛍️ Роздріб 2'}
                </td>
                <td style={{padding: 12}}>{client.email || '-'}</td>
                <td style={{padding: 12}}>
                  <button 
                    onClick={() => handleEdit(client)}
                    style={{marginRight: 10, padding: '5px 10px', background: '#48bb78', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer'}}
                  >
                    ✏️
                  </button>
                  <button 
                    onClick={() => handleDelete(client.id)}
                    style={{padding: '5px 10px', background: '#f56565', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer'}}
                  >
                    🗑️
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {clients.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає клієнтів. Додайте першого клієнта!
          </p>
        )}
      </div>
    </div>
  );
}

export default ClientsPage;
