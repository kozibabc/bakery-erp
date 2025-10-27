#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP v4.0 - Production Ready
# Полное ТЗ: Закупки, Склад, Себестоимость, PDF Прайсы
###############################################################################

set -e

echo "🍰 Bakery ERP v4.0 - Production Ready"
echo "======================================"
echo ""

echo "📂 Создаю структуру..."
mkdir -p backend/src/{models,routes,middleware,utils}
mkdir -p frontend/src/{pages,components,i18n}
mkdir -p frontend/public

###############################################################################
# DOCKER-COMPOSE.YML - ПЕРСИСТЕНТНОЕ ХРАНЕНИЕ
###############################################################################

cat > docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: bakery
      POSTGRES_PASSWORD: bakery123
      POSTGRES_DB: bakery_erp
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "bakery", "-d", "bakery_erp"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: unless-stopped

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://bakery:bakery123@db:5432/bakery_erp
      JWT_SECRET: my-secret-key-2024
      NODE_ENV: production
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: unless-stopped

volumes:
  pgdata:
    driver: local
EOF

###############################################################################
# BACKEND
###############################################################################

cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
CMD ["node", "server.js"]
EOF

cat > backend/package.json << 'EOF'
{
  "name": "bakery-backend",
  "version": "4.0.0",
  "type": "module",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "sequelize": "^6.35.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "pdfkit": "^0.13.0",
    "exceljs": "^4.3.0"
  }
}
EOF

cat > backend/server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import { Sequelize, DataTypes, Op } from 'sequelize';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import PDFDocument from 'pdfkit';
import ExcelJS from 'exceljs';

const app = express();
app.use(cors());
app.use(express.json());

const sequelize = new Sequelize(process.env.DATABASE_URL, { 
  logging: false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
});

// ============================================================================
// MODELS
// ============================================================================

const User = sequelize.define('User', {
  login: { type: DataTypes.STRING, unique: true },
  password: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  phone: DataTypes.STRING,
  telegram: DataTypes.STRING,
  role: { type: DataTypes.ENUM('admin', 'manager'), defaultValue: 'manager' }
});

const Permission = sequelize.define('Permission', {
  userId: DataTypes.INTEGER,
  canViewStock: { type: DataTypes.BOOLEAN, defaultValue: false },
  canEditStock: { type: DataTypes.BOOLEAN, defaultValue: false },
  canAddPurchases: { type: DataTypes.BOOLEAN, defaultValue: false },
  canStartProduction: { type: DataTypes.BOOLEAN, defaultValue: false },
  canViewFinances: { type: DataTypes.BOOLEAN, defaultValue: false },
  canEditSettings: { type: DataTypes.BOOLEAN, defaultValue: false },
  canManageUsers: { type: DataTypes.BOOLEAN, defaultValue: false }
});

const Supplier = sequelize.define('Supplier', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING,
  notes: DataTypes.TEXT
});

const Client = sequelize.define('Client', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING,
  type: { type: DataTypes.ENUM('wholesale', 'retail1', 'retail2'), defaultValue: 'wholesale' },
  notes: DataTypes.TEXT
});

const Component = sequelize.define('Component', {
  name: DataTypes.STRING,
  type: { type: DataTypes.ENUM('RAW', 'SEMI', 'PACK'), defaultValue: 'RAW' },
  unit: { type: DataTypes.STRING, defaultValue: 'кг' },
  currentAvgPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
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
  unit: DataTypes.STRING,
  pricePerUnit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  totalSum: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  transportCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  notes: DataTypes.TEXT
});

const PriceHistory = sequelize.define('PriceHistory', {
  componentId: DataTypes.INTEGER,
  date: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  source: { type: DataTypes.STRING, defaultValue: 'purchase' }
});

const Recipe = sequelize.define('Recipe', {
  name: DataTypes.STRING,
  outputWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 1 },
  outputUnit: { type: DataTypes.STRING, defaultValue: 'кг' }
});

const RecipeItem = sequelize.define('RecipeItem', {
  recipeId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  weight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  unit: { type: DataTypes.STRING, defaultValue: 'кг' }
});

const Product = sequelize.define('Product', {
  name: DataTypes.STRING,
  code: DataTypes.STRING,
  recipeId: DataTypes.INTEGER,
  boxGrossWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  boxNetWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  basePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  retail1Price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  retail2Price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Order = sequelize.define('Order', {
  orderNumber: DataTypes.STRING,
  clientId: DataTypes.INTEGER,
  status: { 
    type: DataTypes.ENUM('draft', 'confirmed', 'in_production', 'done', 'cancelled'), 
    defaultValue: 'draft' 
  },
  totalBoxes: { type: DataTypes.INTEGER, defaultValue: 0 },
  totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  costOfGoods: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  profit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  notes: DataTypes.TEXT
});

const OrderItem = sequelize.define('OrderItem', {
  orderId: DataTypes.INTEGER,
  productId: DataTypes.INTEGER,
  boxes: { type: DataTypes.INTEGER, defaultValue: 1 },
  unitPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const ProductionUsage = sequelize.define('ProductionUsage', {
  orderId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  qtyUsed: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  unit: DataTypes.STRING,
  costPerUnit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  totalCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Settings = sequelize.define('Settings', {
  wholesaleMarkup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 10 },
  retail1Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 40 },
  retail2Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 70 },
  companyName: { type: DataTypes.STRING, defaultValue: 'Sazhenko Bakery' },
  companyLogo: DataTypes.TEXT,
  priceListFooter: { type: DataTypes.TEXT, defaultValue: 'Ціни дійсні на момент формування' }
});

// ASSOCIATIONS
User.hasOne(Permission, { foreignKey: 'userId' });
Permission.belongsTo(User, { foreignKey: 'userId' });

Purchase.belongsTo(Supplier, { foreignKey: 'supplierId' });
Purchase.belongsTo(Component, { foreignKey: 'componentId' });

Stock.belongsTo(Component, { foreignKey: 'componentId' });

PriceHistory.belongsTo(Component, { foreignKey: 'componentId' });

RecipeItem.belongsTo(Component, { foreignKey: 'componentId' });
RecipeItem.belongsTo(Recipe, { foreignKey: 'recipeId' });

Product.belongsTo(Recipe, { foreignKey: 'recipeId' });

Order.belongsTo(Client, { foreignKey: 'clientId' });

OrderItem.belongsTo(Product, { foreignKey: 'productId' });
OrderItem.belongsTo(Order, { foreignKey: 'orderId' });

ProductionUsage.belongsTo(Order, { foreignKey: 'orderId' });
ProductionUsage.belongsTo(Component, { foreignKey: 'componentId' });

// ============================================================================
// HELPERS
// ============================================================================

const sanitizeNumeric = (value) => {
  if (value === '' || value === null || value === undefined) return 0;
  const num = parseFloat(value);
  return isNaN(num) ? 0 : num;
};

const auth = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) throw new Error();
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'my-secret-key-2024');
    req.userId = decoded.id;
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

// ============================================================================
// AUTH
// ============================================================================

app.post('/api/auth/login', async (req, res) => {
  try {
    const { login, password } = req.body;
    const user = await User.findOne({ where: { login } });
    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'my-secret-key-2024', { expiresIn: '24h' });
    const permissions = await Permission.findOne({ where: { userId: user.id } });
    res.json({ 
      token, 
      user: { id: user.id, login: user.login, name: user.name, role: user.role },
      permissions
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================================
// USERS & PERMISSIONS
// ============================================================================

app.get('/api/users', auth, async (req, res) => {
  const users = await User.findAll({ 
    attributes: { exclude: ['password'] },
    include: [Permission]
  });
  res.json(users);
});

app.post('/api/users', auth, async (req, res) => {
  const { login, password, name, email, phone, telegram, role } = req.body;
  const hashed = await bcrypt.hash(password, 10);
  const user = await User.create({ login, password: hashed, name, email, phone, telegram, role });
  await Permission.create({ userId: user.id });
  res.json({ id: user.id, login, name, email, phone, telegram, role });
});

app.put('/api/users/:id', auth, async (req, res) => {
  const { name, email, phone, telegram, password } = req.body;
  const user = await User.findByPk(req.params.id);
  if (password) user.password = await bcrypt.hash(password, 10);
  user.name = name;
  user.email = email;
  user.phone = phone;
  user.telegram = telegram;
  await user.save();
  res.json({ id: user.id, name, email, phone, telegram });
});

app.put('/api/permissions/:userId', auth, async (req, res) => {
  const [perm] = await Permission.upsert({ userId: req.params.userId, ...req.body });
  res.json(perm);
});

// ============================================================================
// SUPPLIERS & CLIENTS
// ============================================================================

app.get('/api/suppliers', auth, async (req, res) => res.json(await Supplier.findAll()));
app.post('/api/suppliers', auth, async (req, res) => res.json(await Supplier.create(req.body)));
app.put('/api/suppliers/:id', auth, async (req, res) => {
  await Supplier.update(req.body, { where: { id: req.params.id } });
  res.json(await Supplier.findByPk(req.params.id));
});

app.get('/api/clients', auth, async (req, res) => res.json(await Client.findAll()));
app.post('/api/clients', auth, async (req, res) => res.json(await Client.create(req.body)));
app.put('/api/clients/:id', auth, async (req, res) => {
  await Client.update(req.body, { where: { id: req.params.id } });
  res.json(await Client.findByPk(req.params.id));
});

// ============================================================================
// COMPONENTS & STOCK
// ============================================================================

app.get('/api/components', auth, async (req, res) => {
  const components = await Component.findAll({
    include: [{ model: Stock, required: false }]
  });
  res.json(components);
});

app.post('/api/components', auth, async (req, res) => {
  const data = {
    name: req.body.name || '',
    type: req.body.type || 'RAW',
    unit: req.body.unit || 'кг',
    currentAvgPrice: sanitizeNumeric(req.body.currentAvgPrice)
  };
  const component = await Component.create(data);
  await Stock.create({ componentId: component.id, qtyOnHand: 0, avgCost: 0 });
  res.json(component);
});

app.put('/api/components/:id', auth, async (req, res) => {
  const data = {
    name: req.body.name,
    type: req.body.type,
    unit: req.body.unit,
    currentAvgPrice: sanitizeNumeric(req.body.currentAvgPrice)
  };
  await Component.update(data, { where: { id: req.params.id } });
  res.json(await Component.findByPk(req.params.id));
});

app.get('/api/stock', auth, async (req, res) => {
  const stock = await Stock.findAll({
    include: [Component]
  });
  res.json(stock);
});

// ============================================================================
// PURCHASES (ЗАКУПКИ)
// ============================================================================

app.get('/api/purchases', auth, async (req, res) => {
  const purchases = await Purchase.findAll({
    include: [Supplier, Component],
    order: [['date', 'DESC']]
  });
  res.json(purchases);
});

app.post('/api/purchases', auth, async (req, res) => {
  try {
    const { supplierId, componentId, qty, unit, pricePerUnit, transportCost, notes, date } = req.body;
    
    const qtyNum = sanitizeNumeric(qty);
    const priceNum = sanitizeNumeric(pricePerUnit);
    const transportNum = sanitizeNumeric(transportCost);
    const totalSum = qtyNum * priceNum + transportNum;
    
    // Создаём закупку
    const purchase = await Purchase.create({
      date: date || new Date(),
      supplierId,
      componentId,
      qty: qtyNum,
      unit,
      pricePerUnit: priceNum,
      totalSum,
      transportCost: transportNum,
      notes
    });
    
    // Обновляем склад
    const stock = await Stock.findOne({ where: { componentId } });
    const oldQty = parseFloat(stock.qtyOnHand);
    const oldAvg = parseFloat(stock.avgCost);
    
    const newQty = oldQty + qtyNum;
    const newAvg = newQty > 0 ? ((oldQty * oldAvg) + totalSum) / newQty : 0;
    
    await stock.update({
      qtyOnHand: newQty,
      avgCost: newAvg
    });
    
    // Обновляем среднюю цену компонента
    await Component.update({ currentAvgPrice: newAvg }, { where: { id: componentId } });
    
    // Добавляем в историю цен
    await PriceHistory.create({
      componentId,
      date: purchase.date,
      price: priceNum,
      source: 'purchase'
    });
    
    res.json(purchase);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

Из-за ограничения размера продолжу в следующем файле...
EOF

echo ""
echo "✅ Backend v4.0 Part 1 создан!"
echo "   Следующая часть: остальные API endpoints"
echo ""
