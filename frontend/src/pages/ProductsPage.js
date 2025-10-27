import React, { useState, useEffect } from 'react';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', basePrice: 0 });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    const res = await fetch('http://localhost:3000/api/products', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setProducts(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await fetch('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(form)
    });
    
    setForm({ name: '', basePrice: 0 });
    setShowForm(false);
    fetchProducts();
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>🍰 Товари</h2>
          <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
            {showForm ? 'Скасувати' : '+ Додати товар'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{marginBottom: 15}}>
              <label>Назва товару *</label>
              <input 
                value={form.name} 
                onChange={e => setForm({...form, name: e.target.value})} 
                placeholder="Торт Наполеон"
                required
              />
            </div>
            <div style={{marginBottom: 15}}>
              <label>Базова ціна (грн) *</label>
              <input 
                type="number"
                step="0.01"
                value={form.basePrice} 
                onChange={e => setForm({...form, basePrice: e.target.value})} 
                placeholder="450.00"
                required
              />
            </div>
            <button type="submit" className="btn btn-primary">Додати</button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Назва</th>
              <th style={{padding: 12, textAlign: 'right'}}>Базова ціна</th>
            </tr>
          </thead>
          <tbody>
            {products.map(product => (
              <tr key={product.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{product.name}</td>
                <td style={{padding: 12, textAlign: 'right'}}>{parseFloat(product.basePrice).toFixed(2)} грн</td>
              </tr>
            ))}
          </tbody>
        </table>

        {products.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає товарів. Додайте перший!
          </p>
        )}
      </div>
    </div>
  );
}

export default ProductsPage;
