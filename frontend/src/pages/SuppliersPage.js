import React, { useState, useEffect } from 'react';

function SuppliersPage() {
  const [suppliers, setSuppliers] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '', notes: '' });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchSuppliers();
  }, []);

  const fetchSuppliers = async () => {
    const res = await fetch('http://localhost:3000/api/suppliers', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setSuppliers(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await fetch('http://localhost:3000/api/suppliers', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(form)
    });
    
    setForm({ name: '', phone: '', email: '', telegram: '', notes: '' });
    setShowForm(false);
    fetchSuppliers();
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>🚚 Постачальники</h2>
          <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
            {showForm ? 'Скасувати' : '+ Додати постачальника'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{marginBottom: 15}}>
              <label>Назва *</label>
              <input 
                value={form.name} 
                onChange={e => setForm({...form, name: e.target.value})} 
                placeholder="ТОВ 'Мельник'"
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
                placeholder="supplier@example.com"
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
              <label>Примітки</label>
              <textarea 
                value={form.notes} 
                onChange={e => setForm({...form, notes: e.target.value})} 
                rows={3}
                style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
              />
            </div>
            <button type="submit" className="btn btn-primary">Додати</button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Назва</th>
              <th style={{padding: 12, textAlign: 'left'}}>Телефон</th>
              <th style={{padding: 12, textAlign: 'left'}}>Email</th>
              <th style={{padding: 12, textAlign: 'left'}}>Telegram</th>
            </tr>
          </thead>
          <tbody>
            {suppliers.map(supplier => (
              <tr key={supplier.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{supplier.name}</td>
                <td style={{padding: 12}}>{supplier.phone || '-'}</td>
                <td style={{padding: 12}}>{supplier.email || '-'}</td>
                <td style={{padding: 12}}>
                  {supplier.telegram ? (
                    <a href={`https://t.me/${supplier.telegram.replace('@', '')}`} target="_blank" rel="noopener noreferrer" className="telegram-link">
                      {supplier.telegram}
                    </a>
                  ) : '-'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {suppliers.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає постачальників. Додайте першого!
          </p>
        )}
      </div>
    </div>
  );
}

export default SuppliersPage;
