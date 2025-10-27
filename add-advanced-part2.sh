#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 - ADVANCED FEATURES Part 2
# Enhanced Recipes (с компонентами) + Users Page
###############################################################################

set -e

echo "🍰 Adding Advanced Features Part 2/3"
echo "===================================="
echo "  ✅ Рецепти (з редагуванням)"
echo "  ✅ Користувачі"
echo ""

###############################################################################
# ENHANCED RECIPES PAGE WITH COMPONENTS
###############################################################################

cat > frontend/src/pages/RecipesPage.js << 'EOFRECIPES'
import React, { useState, useEffect } from 'react';

function RecipesPage() {
  const [recipes, setRecipes] = useState([]);
  const [components, setComponents] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState({ name: '', items: [] });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchRecipes();
    fetchComponents();
  }, []);

  const fetchRecipes = async () => {
    const res = await fetch('http://localhost:3000/api/recipes', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setRecipes(data);
  };

  const fetchComponents = async () => {
    const res = await fetch('http://localhost:3000/api/components', {
      headers: { Authorization: `Bearer ${token}` }
    });
    setComponents(await res.json());
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const url = editingId 
      ? `http://localhost:3000/api/recipes/${editingId}`
      : 'http://localhost:3000/api/recipes';
    const method = editingId ? 'PUT' : 'POST';
    
    await fetch(url, {
      method,
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(form)
    });
    
    setForm({ name: '', items: [] });
    setEditingId(null);
    setShowForm(false);
    fetchRecipes();
  };

  const handleEdit = (recipe) => {
    setForm({ 
      name: recipe.name, 
      items: recipe.RecipeItems?.map(item => ({
        componentId: item.componentId,
        weight: item.weight
      })) || []
    });
    setEditingId(recipe.id);
    setShowForm(true);
  };

  const addItem = () => {
    setForm({
      ...form,
      items: [...form.items, { componentId: '', weight: 0 }]
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
          <h2>📋 Рецепти</h2>
          <button className="btn btn-primary" onClick={() => {
            setShowForm(!showForm);
            setEditingId(null);
            setForm({ name: '', items: [] });
          }}>
            {showForm ? 'Скасувати' : '+ Додати рецепт'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{marginBottom: 15}}>
              <label>Назва рецепту *</label>
              <input 
                value={form.name} 
                onChange={e => setForm({...form, name: e.target.value})} 
                placeholder="Бісквітний корж"
                required
              />
            </div>

            <div style={{marginBottom: 15}}>
              <label>Компоненти</label>
              {form.items.map((item, index) => (
                <div key={index} style={{display: 'flex', gap: 10, marginBottom: 10}}>
                  <select 
                    value={item.componentId}
                    onChange={e => updateItem(index, 'componentId', e.target.value)}
                    style={{flex: 2, padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                    required
                  >
                    <option value="">Оберіть компонент...</option>
                    {components.map(c => (
                      <option key={c.id} value={c.id}>{c.name} ({c.unit})</option>
                    ))}
                  </select>
                  <input 
                    type="number"
                    step="0.001"
                    value={item.weight}
                    onChange={e => updateItem(index, 'weight', e.target.value)}
                    placeholder="Вага"
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
                + Додати компонент
              </button>
            </div>

            <button type="submit" className="btn btn-primary">
              {editingId ? 'Оновити рецепт' : 'Додати рецепт'}
            </button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Назва</th>
              <th style={{padding: 12, textAlign: 'left'}}>Компоненти</th>
              <th style={{padding: 12, textAlign: 'left'}}>Дія</th>
            </tr>
          </thead>
          <tbody>
            {recipes.map(recipe => (
              <tr key={recipe.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}><strong>{recipe.name}</strong></td>
                <td style={{padding: 12}}>
                  {recipe.RecipeItems?.length > 0 ? (
                    <ul style={{margin: 0, paddingLeft: 20}}>
                      {recipe.RecipeItems.map(item => (
                        <li key={item.id}>
                          {item.Component?.name}: {parseFloat(item.weight).toFixed(3)} {item.Component?.unit}
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <span style={{color: '#999'}}>Немає компонентів</span>
                  )}
                </td>
                <td style={{padding: 12}}>
                  <button 
                    onClick={() => handleEdit(recipe)}
                    style={{padding: '5px 15px', background: '#48bb78', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer'}}
                  >
                    ✏️ Редагувати
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {recipes.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає рецептів. Додайте перший!
          </p>
        )}
      </div>
    </div>
  );
}

export default RecipesPage;
EOFRECIPES

###############################################################################
# USERS PAGE
###############################################################################

cat > frontend/src/pages/UsersPage.js << 'EOFUSERS'
import React, { useState, useEffect } from 'react';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState({ 
    login: '', 
    password: '', 
    name: '', 
    email: '', 
    role: 'manager' 
  });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    const res = await fetch('http://localhost:3000/api/users', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setUsers(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const url = editingId 
      ? `http://localhost:3000/api/users/${editingId}`
      : 'http://localhost:3000/api/users';
    const method = editingId ? 'PUT' : 'POST';
    
    const body = { ...form };
    if (editingId && !form.password) {
      delete body.password;
    }
    
    await fetch(url, {
      method,
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(body)
    });
    
    setForm({ login: '', password: '', name: '', email: '', role: 'manager' });
    setEditingId(null);
    setShowForm(false);
    fetchUsers();
  };

  const handleEdit = (user) => {
    setForm({ 
      login: user.login, 
      password: '', 
      name: user.name || '', 
      email: user.email || '', 
      role: user.role 
    });
    setEditingId(user.id);
    setShowForm(true);
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>👤 Користувачі</h2>
          <button className="btn btn-primary" onClick={() => {
            setShowForm(!showForm);
            setEditingId(null);
            setForm({ login: '', password: '', name: '', email: '', role: 'manager' });
          }}>
            {showForm ? 'Скасувати' : '+ Додати користувача'}
          </button>
        </div>

        {showForm && (
          <form onSubmit={handleSubmit} style={{marginBottom: 20, padding: 20, background: '#f5f7fa', borderRadius: 8}}>
            <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 15}}>
              <div>
                <label>Логін *</label>
                <input 
                  value={form.login} 
                  onChange={e => setForm({...form, login: e.target.value})} 
                  placeholder="user123"
                  required
                  disabled={editingId}
                />
              </div>
              <div>
                <label>Пароль {editingId ? '(залиште порожнім, щоб не змінювати)' : '*'}</label>
                <input 
                  type="password"
                  value={form.password} 
                  onChange={e => setForm({...form, password: e.target.value})} 
                  placeholder="********"
                  required={!editingId}
                />
              </div>
              <div>
                <label>Ім'я</label>
                <input 
                  value={form.name} 
                  onChange={e => setForm({...form, name: e.target.value})} 
                  placeholder="Іван Петренко"
                />
              </div>
              <div>
                <label>Email</label>
                <input 
                  type="email"
                  value={form.email} 
                  onChange={e => setForm({...form, email: e.target.value})} 
                  placeholder="user@example.com"
                />
              </div>
              <div>
                <label>Роль</label>
                <select 
                  value={form.role} 
                  onChange={e => setForm({...form, role: e.target.value})}
                  style={{width: '100%', padding: 10, borderRadius: 5, border: '1px solid #ddd'}}
                >
                  <option value="manager">Менеджер</option>
                  <option value="admin">Адміністратор</option>
                </select>
              </div>
            </div>
            <button type="submit" className="btn btn-primary" style={{marginTop: 15}}>
              {editingId ? 'Оновити' : 'Додати'}
            </button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Логін</th>
              <th style={{padding: 12, textAlign: 'left'}}>Ім'я</th>
              <th style={{padding: 12, textAlign: 'left'}}>Email</th>
              <th style={{padding: 12, textAlign: 'left'}}>Роль</th>
              <th style={{padding: 12, textAlign: 'left'}}>Дія</th>
            </tr>
          </thead>
          <tbody>
            {users.map(user => (
              <tr key={user.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}><strong>{user.login}</strong></td>
                <td style={{padding: 12}}>{user.name || '-'}</td>
                <td style={{padding: 12}}>{user.email || '-'}</td>
                <td style={{padding: 12}}>
                  {user.role === 'admin' && '👑 Адмін'}
                  {user.role === 'manager' && '👔 Менеджер'}
                </td>
                <td style={{padding: 12}}>
                  <button 
                    onClick={() => handleEdit(user)}
                    style={{padding: '5px 15px', background: '#48bb78', color: 'white', border: 'none', borderRadius: 5, cursor: 'pointer'}}
                  >
                    ✏️ Редагувати
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {users.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Немає користувачів
          </p>
        )}
      </div>
    </div>
  );
}

export default UsersPage;
EOFUSERS

echo "✅ Part 2/3 - Enhanced Recipes & Users створено"
echo ""
echo "▶️  Запустите: ./add-advanced-part3.sh"
echo ""
