#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP v3.2 - Part 3 (Pages)
# Запустите ПОСЛЕ Part 1 и Part 2
###############################################################################

set -e

echo "🍰 Bakery ERP v3.2 - Pages (Part 3)"
echo "===================================="
echo ""

cat > frontend/src/pages/UsersPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import TelegramLink from '../components/TelegramLink';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState({ login: '', password: '', name: '', email: '', phone: '', telegram: '' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadUsers(); }, []);

  const loadUsers = () => {
    axios.get('http://localhost:3000/api/users', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setUsers(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/users/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadUsers(); setEditing(null); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); });
    } else {
      axios.post('http://localhost:3000/api/users', { ...form, role: 'manager' }, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadUsers(); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); });
    }
  };

  const handleEdit = (user) => {
    setForm({ login: user.login, password: '', name: user.name, email: user.email || '', phone: user.phone || '', telegram: user.telegram || '' });
    setEditing(user.id);
  };

  return (
    <div className="card">
      <h2>{t('users')}</h2>
      <div className="form-group">
        <label>{t('login')}</label>
        <input value={form.login} onChange={e => setForm({...form, login: e.target.value})} disabled={editing} />
      </div>
      <div className="form-group">
        <label>{t('password')}</label>
        <input type="password" value={form.password} onChange={e => setForm({...form, password: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('name')}</label>
        <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('email')}</label>
        <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('phone')}</label>
        <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} />
      </div>
      <div className="form-group">
        <label>{t('telegram')}</label>
        <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder="@username" />
      </div>
      <button className="btn btn-primary" onClick={handleSubmit}>
        {editing ? t('save') : t('add')}
      </button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ login: '', password: '', name: '', email: '', phone: '', telegram: '' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('login')}</th><th>{t('name')}</th><th>{t('email')}</th><th>{t('phone')}</th><th>Telegram</th><th></th></tr></thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.login}</td>
              <td>{u.name}</td>
              <td>{u.email}</td>
              <td>{u.phone}</td>
              <td><TelegramLink username={u.telegram} /></td>
              <td><button className="btn btn-warning" onClick={() => handleEdit(u)}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default UsersPage;
EOF

cat > frontend/src/pages/SuppliersPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import TelegramLink from '../components/TelegramLink';

function SuppliersPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/suppliers', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/suppliers/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '' }); });
    } else {
      axios.post('http://localhost:3000/api/suppliers', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', phone: '', email: '', telegram: '' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('suppliers')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder={t('phone')} />
      <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder={t('email')} />
      <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder="@username" />
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('phone')}</th><th>{t('email')}</th><th>Telegram</th><th></th></tr></thead>
        <tbody>
          {items.map(s => (
            <tr key={s.id}>
              <td>{s.name}</td>
              <td>{s.phone}</td>
              <td>{s.email}</td>
              <td><TelegramLink username={s.telegram} /></td>
              <td><button className="btn btn-warning" onClick={() => { setForm(s); setEditing(s.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default SuppliersPage;
EOF

cat > frontend/src/pages/ClientsPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import TelegramLink from '../components/TelegramLink';

function ClientsPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/clients', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/clients/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); });
    } else {
      axios.post('http://localhost:3000/api/clients', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('clients')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder={t('phone')} />
      <input value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder={t('email')} />
      <input value={form.telegram} onChange={e => setForm({...form, telegram: e.target.value})} placeholder="@username" />
      <select value={form.type} onChange={e => setForm({...form, type: e.target.value})}>
        <option value="wholesale">{t('wholesale')} (+10%)</option>
        <option value="retail1">{t('retail1')} (+40%)</option>
        <option value="retail2">{t('retail2')} (+70%)</option>
      </select>
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', phone: '', email: '', telegram: '', type: 'wholesale' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('type')}</th><th>{t('phone')}</th><th>Telegram</th><th></th></tr></thead>
        <tbody>
          {items.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{t(c.type)}</td>
              <td>{c.phone}</td>
              <td><TelegramLink username={c.telegram} /></td>
              <td><button className="btn btn-warning" onClick={() => { setForm(c); setEditing(c.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ClientsPage;
EOF

cat > frontend/src/pages/ComponentsPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function ComponentsPage() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: '', price: '', quantity: '', unit: 'кг' });
  const [editing, setEditing] = useState(null);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => { loadData(); }, []);

  const loadData = () => {
    axios.get('http://localhost:3000/api/components', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setItems(res.data));
  };

  const handleSubmit = () => {
    if (editing) {
      axios.put(`http://localhost:3000/api/components/${editing}`, form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setEditing(null); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); });
    } else {
      axios.post('http://localhost:3000/api/components', form, { headers: { Authorization: `Bearer ${token}` } })
        .then(() => { loadData(); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); });
    }
  };

  return (
    <div className="card">
      <h2>{t('components')}</h2>
      <input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder={t('name')} />
      <input value={form.price} onChange={e => setForm({...form, price: e.target.value})} placeholder={t('price')} type="number" step="0.01" />
      <input value={form.quantity} onChange={e => setForm({...form, quantity: e.target.value})} placeholder={t('quantity')} type="number" step="0.001" />
      <select value={form.unit} onChange={e => setForm({...form, unit: e.target.value})}>
        <option>кг</option>
        <option>г</option>
        <option>л</option>
        <option>мл</option>
        <option>шт</option>
      </select>
      <button className="btn btn-primary" onClick={handleSubmit}>{editing ? t('save') : t('add')}</button>
      {editing && <button className="btn" onClick={() => { setEditing(null); setForm({ name: '', price: '', quantity: '', unit: 'кг' }); }}>{t('cancel')}</button>}
      <table>
        <thead><tr><th>{t('name')}</th><th>{t('price')}</th><th>{t('quantity')}</th><th>Од.</th><th></th></tr></thead>
        <tbody>
          {items.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.price} грн</td>
              <td>{c.quantity}</td>
              <td>{c.unit}</td>
              <td><button className="btn btn-warning" onClick={() => { setForm(c); setEditing(c.id); }}>{t('edit')}</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default ComponentsPage;
EOF

cat > frontend/src/pages/ProductsPage.js << 'EOF'
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
EOF

echo "✅ Part 3 створено!"
echo ""
echo "📋 Залишилось: RecipesPage, OrdersPage, AnalyticsPage, SettingsPage"
echo ""
