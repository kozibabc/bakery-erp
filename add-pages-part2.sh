#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 - ADD FUNCTIONAL PAGES Part 2
# Components & Products & Recipes
###############################################################################

set -e

echo "🍰 Adding Pages Part 2/3"
echo "========================"
echo ""

###############################################################################
# COMPONENTS PAGE
###############################################################################

cat > frontend/src/pages/ComponentsPage.js << 'EOFCOMPONENTS'
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
EOFCOMPONENTS

###############################################################################
# PRODUCTS PAGE
###############################################################################

cat > frontend/src/pages/ProductsPage.js << 'EOFPRODUCTS'
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
EOFPRODUCTS

###############################################################################
# RECIPES PAGE
###############################################################################

cat > frontend/src/pages/RecipesPage.js << 'EOFRECIPES'
import React, { useState, useEffect } from 'react';

function RecipesPage() {
  const [recipes, setRecipes] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '' });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchRecipes();
  }, []);

  const fetchRecipes = async () => {
    const res = await fetch('http://localhost:3000/api/recipes', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setRecipes(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await fetch('http://localhost:3000/api/recipes', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(form)
    });
    
    setForm({ name: '' });
    setShowForm(false);
    fetchRecipes();
  };

  return (
    <div>
      <div className="card">
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20}}>
          <h2>📋 Рецепти</h2>
          <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
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
            <button type="submit" className="btn btn-primary">Додати</button>
          </form>
        )}

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Назва</th>
              <th style={{padding: 12, textAlign: 'left'}}>Дата створення</th>
            </tr>
          </thead>
          <tbody>
            {recipes.map(recipe => (
              <tr key={recipe.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{recipe.name}</td>
                <td style={{padding: 12}}>{new Date(recipe.createdAt).toLocaleDateString('uk-UA')}</td>
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

echo "✅ Part 2/3 - Components, Products, Recipes створено"
echo ""
echo "▶️  Запустите: ./add-pages-part3.sh"
echo ""
