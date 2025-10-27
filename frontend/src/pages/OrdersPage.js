import React, { useState, useEffect } from 'react';

function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [clients, setClients] = useState([]);
  const [products, setProducts] = useState([]);
  const [form, setForm] = useState({ 
    orderNumber: `ORD-${Date.now()}`, 
    clientId: '',
    items: []
  });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchOrders();
    fetchClients();
    fetchProducts();
  }, []);

  const fetchOrders = async () => {
    const res = await fetch('http://localhost:3000/api/orders', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setOrders(data);
  };

  const fetchClients = async () => {
    const res = await fetch('http://localhost:3000/api/clients', {
      headers: { Authorization: `Bearer ${token}` }
    });
    setClients(await res.json());
  };

  const fetchProducts = async () => {
    const res = await fetch('http://localhost:3000/api/products', {
      headers: { Authorization: `Bearer ${token}` }
    });
    setProducts(await res.json());
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const method = editingId ? 'PUT' : 'POST';
    const url = editingId 
      ? `http://localhost:3000/api/orders/${editingId}`
      : 'http://localhost:3000/api/orders';

    const res = await fetch(url, {
      method,
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({
        orderNumber: form.orderNumber,
        clientId: form.clientId
      })
    });

    const order = await res.json();

    // Добавить items если есть
    if (form.items.length > 0 && !editingId) {
      for (const item of form.items) {
        await fetch(`http://localhost:3000/api/orders/${order.id}/items`, {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`
          },
          body: JSON.stringify(item)
        });
      }
    }
    
    setForm({ orderNumber: `ORD-${Date.now()}`, clientId: '', items: [] });
    setEditingId(null);
    setShowForm(false);
    fetchOrders();
  };

  const handleComplete = async (orderId) => {
    if (!window.confirm('Виконати замовлення? Це списує товар зі складу.')) return;
    
    await fetch(`http://localhost:3000/api/orders/${orderId}/complete`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` }
    });
    fetchOrders();
  };

  const addItem = () => {
    setForm({
      ...form,
      items: [...form.items, { productId: '', boxes: 1, unitPrice: 0 }]
    });
  };

  const updateItem = (index, field, value) => {
    const newItems = [...form.items];
    newItems[index][field] = value;
    setForm({ ...form, items: newItems });
  };

  const removeItem = (index) => {
    setForm({
      ...form,
      items: form.items.filter((_, i) => i !== index)
    });
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>📝 Замовлення</h2>
          <button className="btn btn-primary" onClick={() => {
            setShowForm(!showForm);
            setEditingId(null);
            setForm({ orderNumber: `ORD-${Date.now()}`, clientId: '', items: [] });
          }}>
            {showForm ? 'Скасувати' : '+ Створити замовлення'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{marginBottom: 15}}>
              <label>Номер замовлення</label>
              <input 
                value={form.orderNumber} 
                onChange={e => setForm({...form, orderNumber: e.target.value})} 
                readOnly
                style={{background: '#e2e8f0'}}
              />
            </div>
            <div style={{marginBottom: 15}}>
              <label>Клієнт *</label>
              <select 
                value={form.clientId} 
                onChange={e => setForm({...form, clientId: e.target.value})}
                style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                required
              >
                <option value="">Оберіть клієнта...</option>
                {clients.map(client => (
                  <option key={client.id} value={client.id}>{client.name}</option>
                ))}
              </select>
            </div>

            <div style={{marginBottom: 15}}>
              <label>Товари</label>
              {form.items.map((item, index) => (
                <div key={index} style={{display: 'flex', gap: 10, marginBottom: 10}}>
                  <select 
                    value={item.productId}
                    onChange={e => updateItem(index, 'productId', e.target.value)}
                    style={{flex: 2, padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                    required
                  >
                    <option value="">Оберіть товар...</option>
                    {products.map(p => (
                      <option key={p.id} value={p.id}>{p.name}</option>
                    ))}
                  </select>
                  <input 
                    type="number"
                    value={item.boxes}
                    onChange={e => updateItem(index, 'boxes', e.target.value)}
                    placeholder="Коробок"
                    style={{flex: 1, padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                    required
                  />
                  <input 
                    type="number"
                    step="0.01"
                    value={item.unitPrice}
                    onChange={e => updateItem(index, 'unitPrice', e.target.value)}
                    placeholder="Ціна"
                    style={{flex: 1, padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                    required
                  />
                  <button 
                    type="button"
                    onClick={() => removeItem(index)}
                    style={{padding: '10px 15px', background: '#f56565', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer'}}
                  >
                    🗑️
                  </button>
                </div>
              ))}
              <button 
                type="button"
                onClick={addItem}
                style={{padding: '10px 20px', background: '#48bb78', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer', marginTop: 10}}
              >
                + Додати товар
              </button>
            </div>

            <button type="submit" className="btn btn-primary">
              {editingId ? 'Оновити' : 'Створити замовлення'}
            </button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Номер</th>
              <th style={{padding: 12, textAlign: 'left'}}>Клієнт</th>
              <th style={{padding: 12, textAlign: 'left'}}>Статус</th>
              <th style={{padding: 12, textAlign: 'left'}}>Дата</th>
              <th style={{padding: 12, textAlign: 'left'}}>Дії</th>
            </tr>
          </thead>
          <tbody>
            {orders.map(order => (
              <tr key={order.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}><strong>{order.orderNumber}</strong></td>
                <td style={{padding: 12}}>{order.Client?.name || '-'}</td>
                <td style={{padding: 12}}>
                  {order.status === 'draft' && '📋 Чернетка'}
                  {order.status === 'in_production' && '⚙️ У виробництві'}
                  {order.status === 'done' && '✅ Виконано'}
                </td>
                <td style={{padding: 12}}>{new Date(order.createdAt).toLocaleDateString('uk-UA')}</td>
                <td style={{padding: 12}}>
                  {order.status === 'draft' && (
                    <button 
                      onClick={() => handleComplete(order.id)}
                      style={{padding: '5px 15px', background: '#48bb78', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer', marginRight: 10}}
                    >
                      ✅ Виконати
                    </button>
                  )}
                  <button 
                    style={{padding: '5px 15px', background: '#667eea', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer'}}
                  >
                    📄 PDF
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {orders.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає замовлень. Створіть перше!
          </p>
        )}
      </div>
    </div>
  );
}

export default OrdersPage;
