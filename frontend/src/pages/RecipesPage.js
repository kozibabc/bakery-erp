import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function RecipesPage() {
  const [recipes, setRecipes] = useState([]);
  const [components, setComponents] = useState([]);
  const [form, setForm] = useState({ name: '', outputWeight: 1, items: [] });
  const [showModal, setShowModal] = useState(false);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    loadData();
    axios.get('http://localhost:3000/api/components', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setComponents(res.data));
  }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/recipes', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setRecipes(res.data));
  };

  const addItem = () => {
    setForm({...form, items: [...form.items, { componentId: '', weight: '' }]});
  };

  const updateItem = (idx, field, value) => {
    const items = [...form.items];
    items[idx][field] = value;
    setForm({...form, items});
  };

  const handleSubmit = () => {
    axios.post('http://localhost:3000/api/recipes', form, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => { loadData(); setForm({ name: '', outputWeight: 1, items: [] }); setShowModal(false); });
  };

  return (
    <div className="card">
      <h2>{t('recipes')}</h2>
      <button className="btn btn-primary" onClick={() => setShowModal(true)}>{t('add')}</button>
      <table>
        <thead><tr><th>{t('name')}</th><th>Вихід (кг)</th></tr></thead>
        <tbody>
          {recipes.map(r => <tr key={r.id}><td>{r.name}</td><td>{r.outputWeight}</td></tr>)}
        </tbody>
      </table>

      {showModal && (
        <div className="modal">
          <div className="modal-content">
            <h3>Новий рецепт</h3>
            <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
            <input value={form.outputWeight} onChange={e => setForm({...form, outputWeight: e.target.value})} placeholder="Вихід (кг)" type="number" step="0.01" />
            <h4>Склад:</h4>
            {form.items.map((item, idx) => (
              <div key={idx} style={{display: 'flex', gap: 10, marginBottom: 10}}>
                <select value={item.componentId} onChange={e => updateItem(idx, 'componentId', e.target.value)}>
                  <option value="">Оберіть компонент</option>
                  {components.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
                <input value={item.weight} onChange={e => updateItem(idx, 'weight', e.target.value)} placeholder="Вага на 1 кг" type="number" step="0.001" />
              </div>
            ))}
            <button className="btn btn-success" onClick={addItem}>+ Компонент</button>
            <div style={{marginTop: 20}}>
              <button className="btn btn-primary" onClick={handleSubmit}>{t('save')}</button>
              <button className="btn" onClick={() => { setShowModal(false); setForm({ name: '', outputWeight: 1, items: [] }); }}>{t('cancel')}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default RecipesPage;
