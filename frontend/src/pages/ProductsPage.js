import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [name, setName] = useState('');
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    axios.get('http://localhost:3000/api/products', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setProducts(res.data))
      .catch(console.error);
  }, [token]);

  const handleAdd = () => {
    axios.post('http://localhost:3000/api/products', { name }, { headers: { Authorization: `Bearer ${token}` } })
      .then(res => { setProducts([...products, res.data]); setName(''); })
      .catch(alert);
  };

  return (
    <div className="card">
      <h2>{t('products')}</h2>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder={t('name')} />
      <button className="primary" onClick={handleAdd}>{t('add')}</button>
      <table>
        <thead><tr><th>{t('name')}</th></tr></thead>
        <tbody>
          {products.map(p => <tr key={p.id}><td>{p.name}</td></tr>)}
        </tbody>
      </table>
    </div>
  );
}

export default ProductsPage;
