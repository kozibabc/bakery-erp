import React, { useState, useEffect } from 'react';

function ComponentsPage() {
  const [components, setComponents] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', type: 'RAW', unit: 'кг' });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchComponents();
  }, []);

  const fetchComponents = async () => {
    const res = await fetch('http://localhost:3000/api/components', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setComponents(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await fetch('http://localhost:3000/api/components', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(form)
    });
    
    setForm({ name: '', type: 'RAW', unit: 'кг' });
    setShowForm(false);
    fetchComponents();
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>🧩 Компоненти</h2>
          <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
            {showForm ? 'Скасувати' : '+ Додати компонент'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{marginBottom: 15}}>
              <label>Назва *</label>
              <input 
                value={form.name} 
                onChange={e => setForm({...form, name: e.target.value})} 
                placeholder="Мука пшеничная"
                required
              />
            </div>
            <div style={{marginBottom: 15}}>
              <label>Тип</label>
              <select 
                value={form.type} 
                onChange={e => setForm({...form, type: e.target.value})}
                style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
              >
                <option value="RAW">Сировина</option>
                <option value="PACK">Упаковка</option>
              </select>
            </div>
            <div style={{marginBottom: 15}}>
              <label>Одиниця виміру</label>
              <select 
                value={form.unit} 
                onChange={e => setForm({...form, unit: e.target.value})}
                style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
              >
                <option value="кг">кг</option>
                <option value="г">г</option>
                <option value="л">л</option>
                <option value="мл">мл</option>
                <option value="шт">шт</option>
              </select>
            </div>
            <button type="submit" className="btn btn-primary">Додати</button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Назва</th>
              <th style={{padding: 12, textAlign: 'left'}}>Тип</th>
              <th style={{padding: 12, textAlign: 'left'}}>Одиниця</th>
            </tr>
          </thead>
          <tbody>
            {components.map(comp => (
              <tr key={comp.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{comp.name}</td>
                <td style={{padding: 12}}>
                  {comp.type === 'RAW' && '🌾 Сировина'}
                  {comp.type === 'PACK' && '📦 Упаковка'}
                </td>
                <td style={{padding: 12}}>{comp.unit}</td>
              </tr>
            ))}
          </tbody>
        </table>

        {components.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає компонентів. Додайте перший!
          </p>
        )}
      </div>
    </div>
  );
}

export default ComponentsPage;
