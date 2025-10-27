import React, { useState, useEffect } from 'react';

function PurchasesPage() {
  const [purchases, setPurchases] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [suppliers, setSuppliers] = useState([]);
  const [components, setComponents] = useState([]);
  const [form, setForm] = useState({
    date: new Date().toISOString().split('T')[0],
    supplierId: '',
    componentId: '',
    qty: 0,
    pricePerUnit: 0,
    notes: ''
  });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchPurchases();
    fetchSuppliers();
    fetchComponents();
  }, []);

  const fetchPurchases = async () => {
    const res = await fetch('http://localhost:3000/api/purchases', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setPurchases(data);
  };

  const fetchSuppliers = async () => {
    const res = await fetch('http://localhost:3000/api/suppliers', {
      headers: { Authorization: `Bearer ${token}` }
    });
    setSuppliers(await res.json());
  };

  const fetchComponents = async () => {
    const res = await fetch('http://localhost:3000/api/components', {
      headers: { Authorization: `Bearer ${token}` }
    });
    setComponents(await res.json());
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await fetch('http://localhost:3000/api/purchases', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(form)
    });
    
    setForm({
      date: new Date().toISOString().split('T')[0],
      supplierId: '',
      componentId: '',
      qty: 0,
      pricePerUnit: 0,
      notes: ''
    });
    setShowForm(false);
    fetchPurchases();
  };

  const totalSum = parseFloat(form.qty || 0) * parseFloat(form.pricePerUnit || 0);

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>📦 Закупки</h2>
          <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
            {showForm ? 'Скасувати' : '+ Додати закупку'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 15}}>
              <div>
                <label>Дата *</label>
                <input 
                  type="date"
                  value={form.date} 
                  onChange={e => setForm({...form, date: e.target.value})} 
                  required
                />
              </div>
              <div>
                <label>Постачальник *</label>
                <select 
                  value={form.supplierId} 
                  onChange={e => setForm({...form, supplierId: e.target.value})}
                  style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                  required
                >
                  <option value="">Оберіть...</option>
                  {suppliers.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>
              <div>
                <label>Компонент *</label>
                <select 
                  value={form.componentId} 
                  onChange={e => setForm({...form, componentId: e.target.value})}
                  style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                  required
                >
                  <option value="">Оберіть...</option>
                  {components.map(c => <option key={c.id} value={c.id}>{c.name} ({c.unit})</option>)}
                </select>
              </div>
              <div>
                <label>Кількість *</label>
                <input 
                  type="number"
                  step="0.001"
                  value={form.qty} 
                  onChange={e => setForm({...form, qty: e.target.value})} 
                  required
                />
              </div>
              <div>
                <label>Ціна за одиницю (грн) *</label>
                <input 
                  type="number"
                  step="0.01"
                  value={form.pricePerUnit} 
                  onChange={e => setForm({...form, pricePerUnit: e.target.value})} 
                  required
                />
              </div>
              <div>
                <label>Сума</label>
                <input 
                  value={totalSum.toFixed(2) + ' грн'}
                  readOnly
                  style={{background: '#e2e8f0'}}
                />
              </div>
            </div>
            <div style={{marginTop: 15}}>
              <label>Примітки</label>
              <textarea 
                value={form.notes} 
                onChange={e => setForm({...form, notes: e.target.value})} 
                rows={2}
                style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
              />
            </div>
            <button type="submit" className="btn btn-primary" style={{marginTop: 15}}>
              Додати закупку
            </button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Дата</th>
              <th style={{padding: 12, textAlign: 'left'}}>Постачальник</th>
              <th style={{padding: 12, textAlign: 'left'}}>Компонент</th>
              <th style={{padding: 12, textAlign: 'right'}}>Кількість</th>
              <th style={{padding: 12, textAlign: 'right'}}>Ціна</th>
              <th style={{padding: 12, textAlign: 'right'}}>Сума</th>
            </tr>
          </thead>
          <tbody>
            {purchases.map(purchase => (
              <tr key={purchase.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{new Date(purchase.date).toLocaleDateString('uk-UA')}</td>
                <td style={{padding: 12}}>{purchase.Supplier?.name || '-'}</td>
                <td style={{padding: 12}}>{purchase.Component?.name || '-'}</td>
                <td style={{padding: 12, textAlign: 'right'}}>{parseFloat(purchase.qty).toFixed(3)}</td>
                <td style={{padding: 12, textAlign: 'right'}}>{parseFloat(purchase.pricePerUnit).toFixed(2)} грн</td>
                <td style={{padding: 12, textAlign: 'right'}}><strong>{parseFloat(purchase.totalSum).toFixed(2)} грн</strong></td>
              </tr>
            ))}
          </tbody>
        </table>

        {purchases.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає закупок. Додайте першу!
          </p>
        )}
      </div>
    </div>
  );
}

export default PurchasesPage;
