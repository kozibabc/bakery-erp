import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [recipes, setRecipes] = useState([]);
  const [form, setForm] = useState({ name: '', recipeId: '', boxNetWeight: '', basePrice: '' });
  const [editing, setEditing] = useState(null);
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
    const selectedRecipe = recipes.find(r => r.id === parseInt(form.recipeId));
    const boxGrossWeight = selectedRecipe ? selectedRecipe.outputWeight : 0;
    
    const data = { ...form, boxGrossWeight };
    
    if (editing) {
      axios.put(`http://localhost:3000/api/products/${editing}`, data, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', recipeId: '', boxNetWeight: '', basePrice: '' }); });
    } else {
      axios.post('http://localhost:3000/api/products', data, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', recipeId: '', boxNetWeight: '', basePrice: '' }); });
    }
  };

  const downloadPricePDF = (type) => {
    window.open(`http://localhost:3000/api/products/price-pdf/${type}`, '_blank');
  };

  return (
    <div className="card">
      <h2>{t('products')}</h2>
      <div style={{marginBottom: 20}}>
        <button className="btn btn-success" onClick={() => downloadPricePDF('wholesale')}>Прайс Опт PDF</button>
        <button className="btn btn-success" onClick={() => downloadPricePDF('retail1')}>Прайс Р1 PDF</button>
        <button className="btn btn-success" onClick={() => downloadPricePDF('retail2')}>Прайс Р2 PDF</button>
      </div>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <select value={form.recipeId} onChange={e => setForm({...form, recipeId: e.target.value})}>
        <option value="">Оберіть рецепт</option>
        {recipes.map(r => <option key={r.id} value={r.id}>{r.name} ({r.outputWeight} {r.outputUnit})</option>)}
      </select>
      <input value={form.boxNetWeight} onChange={e => setForm({...form, boxNetWeight: e.target.value})} placeholder="Нетто (кг)" type="number" step="0.01" />
      <input value={form.basePrice} onChange={e => setForm({...form, basePrice: e.target.value})} placeholder={t('basePrice')} type="number" step="0.01" />
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', recipeId: '', boxNetWeight: '', basePrice: '' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>Брутто</th><th>Нетто</th><th>{t('basePrice')}</th><th></th></tr></thead>
        <tbody>
          {products.map(p => (
            <tr key={p.id}>
              <td>{p.name}</td>
              <td>{p.boxGrossWeight} кг</td>
              <td>{p.boxNetWeight} кг</td>
              <td>{p.basePrice} грн</td>
              <td>
                <button className="btn btn-warning" onClick={() => { 
                  setForm({ name: p.name, recipeId: p.recipeId, boxNetWeight: p.boxNetWeight, basePrice: p.basePrice }); 
                  setEditing(p.id); 
                }}>{t('edit')}</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ProductsPage;
