import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [recipes, setRecipes] = useState([]);
  const [form, setForm] = useState({ name: '', recipeId: '', boxGrossWeight: '', boxNetWeight: '', basePrice: '' });
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadData();
    axios.get('http://localhost:3000/api/recipes', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setRecipes(res.data));
  }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/products', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setProducts(res.data));
  };

  const handleSubmit = () => {
    axios.post('http://localhost:3000/api/products', form, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => { loadData(); setForm({ name: '', recipeId: '', boxGrossWeight: '', boxNetWeight: '', basePrice: '' }); });
  };

  return (
    <div className="card">
      <h2>{t('products')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <select value={form.recipeId} onChange={e => setForm({...form, recipeId: e.target.value})}>
        <option value="">Оберіть рецепт</option>
        {recipes.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
      </select>
      <input value={form.boxGrossWeight} onChange={e => setForm({...form, boxGrossWeight: e.target.value})} placeholder="Брутто (кг)" type="number" step="0.01" />
      <input value={form.boxNetWeight} onChange={e => setForm({...form, boxNetWeight: e.target.value})} placeholder="Нетто (кг)" type="number" step="0.01" />
      <input value={form.basePrice} onChange={e => setForm({...form, basePrice: e.target.value})} placeholder={t('basePrice')} type="number" step="0.01" />
      <button className="btn btn-primary" onClick={handleSubmit}>{t('add')}</button>
      <table>
        <thead><tr><th>{t('name')}</th><th>Брутто</th><th>Нетто</th><th>{t('basePrice')}</th></tr></thead>
        <tbody>
          {products.map(p => (
            <tr key={p.id}>
              <td>{p.name}</td>
              <td>{p.boxGrossWeight} кг</td>
              <td>{p.boxNetWeight} кг</td>
              <td>{p.basePrice} грн</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ProductsPage;
