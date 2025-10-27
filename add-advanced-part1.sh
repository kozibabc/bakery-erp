#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 - ADVANCED FEATURES Part 1
# Purchases (Закупки) + Stock (Склад) + Enhanced Backend
###############################################################################

set -e

echo "🍰 Adding Advanced Features Part 1/3"
echo "===================================="
echo "  ✅ Закупки (Purchases)"
echo "  ✅ Склад (Stock)"
echo "  ✅ Backend API расширение"
echo ""

###############################################################################
# BACKEND - ADD MODELS TO SERVER.JS
###############################################################################

cat > backend/src/server.js << 'EOFSERVER'
import express from 'express';
import cors from 'cors';
import { Sequelize, DataTypes } from 'sequelize';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const app = express();
app.use(cors());
app.use(express.json());

const sequelize = new Sequelize(process.env.DATABASE_URL, { logging: false });

// Models
const User = sequelize.define('User', {
  login: { type: DataTypes.STRING, unique: true },
  password: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  role: { type: DataTypes.ENUM('admin', 'manager'), defaultValue: 'manager' }
});

const Client = sequelize.define('Client', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING,
  type: { type: DataTypes.ENUM('wholesale', 'retail1', 'retail2'), defaultValue: 'wholesale' },
  notes: DataTypes.TEXT
});

const Supplier = sequelize.define('Supplier', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING,
  notes: DataTypes.TEXT
});

const Component = sequelize.define('Component', {
  name: DataTypes.STRING,
  type: { type: DataTypes.ENUM('RAW', 'PACK'), defaultValue: 'RAW' },
  unit: { type: DataTypes.STRING, defaultValue: 'кг' }
});

const Stock = sequelize.define('Stock', {
  componentId: { type: DataTypes.INTEGER, unique: true },
  qtyOnHand: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  avgCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Purchase = sequelize.define('Purchase', {
  date: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  supplierId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  qty: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  pricePerUnit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  totalSum: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  notes: DataTypes.TEXT
});

const Recipe = sequelize.define('Recipe', {
  name: DataTypes.STRING
});

const RecipeItem = sequelize.define('RecipeItem', {
  recipeId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  weight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 }
});

const Product = sequelize.define('Product', {
  name: DataTypes.STRING,
  basePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Order = sequelize.define('Order', {
  orderNumber: DataTypes.STRING,
  clientId: DataTypes.INTEGER,
  status: { type: DataTypes.ENUM('draft', 'in_production', 'done'), defaultValue: 'draft' },
  totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const OrderItem = sequelize.define('OrderItem', {
  orderId: DataTypes.INTEGER,
  productId: DataTypes.INTEGER,
  boxes: { type: DataTypes.INTEGER, defaultValue: 1 },
  unitPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

// Associations
Order.belongsTo(Client, { foreignKey: 'clientId' });
Order.hasMany(OrderItem, { foreignKey: 'orderId' });
OrderItem.belongsTo(Product, { foreignKey: 'productId' });
Stock.belongsTo(Component, { foreignKey: 'componentId' });
Purchase.belongsTo(Supplier, { foreignKey: 'supplierId' });
Purchase.belongsTo(Component, { foreignKey: 'componentId' });
Recipe.hasMany(RecipeItem, { foreignKey: 'recipeId' });
RecipeItem.belongsTo(Component, { foreignKey: 'componentId' });

// Auth
const auth = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    jwt.verify(token, 'my-secret-key-2024');
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

// Routes - Auth
app.post('/api/auth/login', async (req, res) => {
  const { login, password } = req.body;
  const user = await User.findOne({ where: { login } });
  if (!user || !await bcrypt.compare(password, user.password)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  const token = jwt.sign({ id: user.id }, 'my-secret-key-2024', { expiresIn: '8h' });
  res.json({ token, user: { id: user.id, login: user.login, name: user.name } });
});

// Routes - Users
app.get('/api/users', auth, async (req, res) => {
  const users = await User.findAll({ attributes: { exclude: ['password'] } });
  res.json(users);
});
app.post('/api/users', auth, async (req, res) => {
  const hashed = await bcrypt.hash(req.body.password, 10);
  res.json(await User.create({ ...req.body, password: hashed }));
});
app.put('/api/users/:id', auth, async (req, res) => {
  if (req.body.password) {
    req.body.password = await bcrypt.hash(req.body.password, 10);
  }
  await User.update(req.body, { where: { id: req.params.id } });
  res.json(await User.findByPk(req.params.id, { attributes: { exclude: ['password'] } }));
});

// Routes - Clients
app.get('/api/clients', auth, async (req, res) => res.json(await Client.findAll()));
app.post('/api/clients', auth, async (req, res) => res.json(await Client.create(req.body)));
app.put('/api/clients/:id', auth, async (req, res) => {
  await Client.update(req.body, { where: { id: req.params.id } });
  res.json(await Client.findByPk(req.params.id));
});
app.delete('/api/clients/:id', auth, async (req, res) => {
  await Client.destroy({ where: { id: req.params.id } });
  res.json({ message: 'Deleted' });
});

// Routes - Suppliers
app.get('/api/suppliers', auth, async (req, res) => res.json(await Supplier.findAll()));
app.post('/api/suppliers', auth, async (req, res) => res.json(await Supplier.create(req.body)));

// Routes - Components
app.get('/api/components', auth, async (req, res) => res.json(await Component.findAll()));
app.post('/api/components', auth, async (req, res) => res.json(await Component.create(req.body)));

// Routes - Purchases
app.get('/api/purchases', auth, async (req, res) => {
  res.json(await Purchase.findAll({ 
    include: [Supplier, Component],
    order: [['date', 'DESC']]
  }));
});

app.post('/api/purchases', auth, async (req, res) => {
  const { supplierId, componentId, qty, pricePerUnit } = req.body;
  const totalSum = parseFloat(qty) * parseFloat(pricePerUnit);
  
  const purchase = await Purchase.create({
    ...req.body,
    totalSum
  });
  
  // Обновляем склад
  const stock = await Stock.findOne({ where: { componentId } });
  if (stock) {
    const oldQty = parseFloat(stock.qtyOnHand);
    const oldCost = parseFloat(stock.avgCost);
    const newQty = oldQty + parseFloat(qty);
    const newAvg = ((oldQty * oldCost) + totalSum) / newQty;
    await stock.update({ qtyOnHand: newQty, avgCost: newAvg });
  } else {
    await Stock.create({ componentId, qtyOnHand: qty, avgCost: pricePerUnit });
  }
  
  res.json(purchase);
});

// Routes - Stock
app.get('/api/stock', auth, async (req, res) => {
  res.json(await Stock.findAll({ include: [Component] }));
});

// Routes - Recipes
app.get('/api/recipes', auth, async (req, res) => {
  res.json(await Recipe.findAll({ include: [{ model: RecipeItem, include: [Component] }] }));
});

app.post('/api/recipes', auth, async (req, res) => res.json(await Recipe.create(req.body)));

app.put('/api/recipes/:id', auth, async (req, res) => {
  const { name, items } = req.body;
  await Recipe.update({ name }, { where: { id: req.params.id } });
  
  if (items) {
    await RecipeItem.destroy({ where: { recipeId: req.params.id } });
    for (const item of items) {
      await RecipeItem.create({ recipeId: req.params.id, ...item });
    }
  }
  
  res.json(await Recipe.findByPk(req.params.id, { include: [{ model: RecipeItem, include: [Component] }] }));
});

// Routes - Products
app.get('/api/products', auth, async (req, res) => res.json(await Product.findAll()));
app.post('/api/products', auth, async (req, res) => res.json(await Product.create(req.body)));

// Routes - Orders
app.get('/api/orders', auth, async (req, res) => {
  res.json(await Order.findAll({ 
    include: [Client, { model: OrderItem, include: [Product] }],
    order: [['createdAt', 'DESC']]
  }));
});

app.post('/api/orders', auth, async (req, res) => res.json(await Order.create(req.body)));

app.put('/api/orders/:id', auth, async (req, res) => {
  await Order.update(req.body, { where: { id: req.params.id } });
  res.json(await Order.findByPk(req.params.id, { include: [Client] }));
});

app.post('/api/orders/:id/items', auth, async (req, res) => {
  res.json(await OrderItem.create({ orderId: req.params.id, ...req.body }));
});

app.post('/api/orders/:id/complete', auth, async (req, res) => {
  const order = await Order.findByPk(req.params.id, {
    include: [{ model: OrderItem, include: [Product] }]
  });
  
  // Списываем со склада (упрощенная версия)
  // TODO: интеграция с рецептами
  
  await order.update({ status: 'done' });
  res.json(order);
});

// Init
const init = async () => {
  await sequelize.sync({ force: false, alter: true });
  const admin = await User.findOne({ where: { login: 'admin' } });
  if (!admin) {
    const hashed = await bcrypt.hash('admin', 10);
    await User.create({ login: 'admin', password: hashed, name: 'Administrator', role: 'admin' });
  }
  console.log('✅ Database ready');
  app.listen(3000, '0.0.0.0', () => console.log('🚀 Backend v4.1 ADVANCED on :3000'));
};

init();
EOFSERVER

###############################################################################
# PURCHASES PAGE
###############################################################################

cat > frontend/src/pages/PurchasesPage.js << 'EOFPURCHASES'
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
EOFPURCHASES

###############################################################################
# STOCK PAGE
###############################################################################

cat > frontend/src/pages/StockPage.js << 'EOFSTOCK'
import React, { useState, useEffect } from 'react';

function StockPage() {
  const [stock, setStock] = useState([]);

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchStock();
  }, []);

  const fetchStock = async () => {
    const res = await fetch('http://localhost:3000/api/stock', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setStock(data);
  };

  const totalValue = stock.reduce((sum, item) => 
    sum + (parseFloat(item.qtyOnHand) * parseFloat(item.avgCost)), 0
  );

  return (
    <div>
      <div className="card">
        <h2>📊 Склад</h2>
        <p style={{color: '#666', marginTop: 10}}>
          Залишки компонентів на складі
        </p>

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Компонент</th>
              <th style={{padding: 12, textAlign: 'left'}}>Тип</th>
              <th style={{padding: 12, textAlign: 'right'}}>Залишок</th>
              <th style={{padding: 12, textAlign: 'right'}}>Сер. ціна</th>
              <th style={{padding: 12, textAlign: 'right'}}>Вартість</th>
            </tr>
          </thead>
          <tbody>
            {stock.map(item => (
              <tr key={item.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{item.Component?.name || '-'}</td>
                <td style={{padding: 12}}>
                  {item.Component?.type === 'RAW' && '🌾 Сировина'}
                  {item.Component?.type === 'PACK' && '📦 Упаковка'}
                </td>
                <td style={{padding: 12, textAlign: 'right'}}>
                  {parseFloat(item.qtyOnHand).toFixed(3)} {item.Component?.unit}
                </td>
                <td style={{padding: 12, textAlign: 'right'}}>
                  {parseFloat(item.avgCost).toFixed(2)} грн
                </td>
                <td style={{padding: 12, textAlign: 'right'}}>
                  <strong>
                    {(parseFloat(item.qtyOnHand) * parseFloat(item.avgCost)).toFixed(2)} грн
                  </strong>
                </td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr style={{background: '#f7fafc', borderTop: '2px solid #e2e8f0'}}>
              <td colSpan="4" style={{padding: 12, textAlign: 'right'}}><strong>Загальна вартість:</strong></td>
              <td style={{padding: 12, textAlign: 'right'}}>
                <strong style={{color: '#667eea', fontSize: 18}}>
                  {totalValue.toFixed(2)} грн
                </strong>
              </td>
            </tr>
          </tfoot>
        </table>

        {stock.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Склад порожній. Додайте закупки!
          </p>
        )}
      </div>
    </div>
  );
}

export default StockPage;
EOFSTOCK

echo "✅ Part 1/3 - Purchases & Stock створено"
echo ""
echo "▶️  Запустите: ./add-advanced-part2.sh"
echo ""
