#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP v3.2 - Полная версия
# Заказы + PDF генерация + Аналитика + Улучшения
###############################################################################

set -e

echo "🍰 Bakery ERP v3.2 - Расширенная версия"
echo "========================================"
echo ""

echo "📂 Создаю структуру..."
mkdir -p backend frontend/src/{pages,components,i18n} frontend/public

###############################################################################
# DOCKER-COMPOSE.YML
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
      retries: 5

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://bakery:bakery123@db:5432/bakery_erp
      JWT_SECRET: my-secret-key-2024
    depends_on:
      db:
        condition: service_healthy

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend

volumes:
  pgdata:
EOF

###############################################################################
# BACKEND
###############################################################################

cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "server.js"]
EOF

cat > backend/package.json << 'EOF'
{
  "name": "bakery-backend",
  "version": "3.2.0",
  "type": "module",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "sequelize": "^6.35.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "pdfkit": "^0.13.0"
  }
}
EOF

cat > backend/server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import { Sequelize, DataTypes } from 'sequelize';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import PDFDocument from 'pdfkit';

const app = express();
app.use(cors());
app.use(express.json());

const sequelize = new Sequelize(process.env.DATABASE_URL, { logging: false });

// MODELS
const User = sequelize.define('User', {
  login: { type: DataTypes.STRING, unique: true },
  password: DataTypes.STRING,
  name: DataTypes.STRING,
  email: DataTypes.STRING,
  phone: DataTypes.STRING,
  telegram: DataTypes.STRING,
  role: { type: DataTypes.ENUM('admin', 'manager'), defaultValue: 'manager' }
});

const Supplier = sequelize.define('Supplier', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING
});

const Client = sequelize.define('Client', {
  name: DataTypes.STRING,
  phone: DataTypes.STRING,
  email: DataTypes.STRING,
  telegram: DataTypes.STRING,
  type: { type: DataTypes.ENUM('wholesale', 'retail1', 'retail2'), defaultValue: 'wholesale' }
});

const Component = sequelize.define('Component', {
  name: DataTypes.STRING,
  price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  quantity: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  unit: { type: DataTypes.STRING, defaultValue: 'кг' }
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
  recipeId: DataTypes.INTEGER,
  boxGrossWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  boxNetWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  basePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Order = sequelize.define('Order', {
  clientId: DataTypes.INTEGER,
  status: { type: DataTypes.ENUM('open', 'completed', 'cancelled'), defaultValue: 'open' },
  totalBoxes: { type: DataTypes.INTEGER, defaultValue: 0 },
  totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  notes: DataTypes.TEXT
});

const OrderItem = sequelize.define('OrderItem', {
  orderId: DataTypes.INTEGER,
  productId: DataTypes.INTEGER,
  boxes: { type: DataTypes.INTEGER, defaultValue: 1 },
  price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Settings = sequelize.define('Settings', {
  wholesaleMarkup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 10 },
  retail1Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 40 },
  retail2Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 70 }
});

// ASSOCIATIONS
RecipeItem.belongsTo(Component, { foreignKey: 'componentId' });
Product.belongsTo(Recipe, { foreignKey: 'recipeId' });
Order.belongsTo(Client, { foreignKey: 'clientId' });
OrderItem.belongsTo(Product, { foreignKey: 'productId' });
OrderItem.belongsTo(Order, { foreignKey: 'orderId' });

// AUTH MIDDLEWARE
const auth = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) throw new Error();
    jwt.verify(token, process.env.JWT_SECRET || 'my-secret-key-2024');
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

// AUTH
app.post('/api/auth/login', async (req, res) => {
  try {
    const { login, password } = req.body;
    const user = await User.findOne({ where: { login } });
    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'my-secret-key-2024', { expiresIn: '24h' });
    res.json({ token, user: { id: user.id, login: user.login, name: user.name, role: user.role } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// USERS
app.get('/api/users', auth, async (req, res) => {
  const users = await User.findAll({ attributes: { exclude: ['password'] } });
  res.json(users);
});

app.post('/api/users', auth, async (req, res) => {
  const { login, password, name, email, phone, telegram, role } = req.body;
  const hashed = await bcrypt.hash(password, 10);
  const user = await User.create({ login, password: hashed, name, email, phone, telegram, role });
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

// SUPPLIERS
app.get('/api/suppliers', auth, async (req, res) => res.json(await Supplier.findAll()));
app.post('/api/suppliers', auth, async (req, res) => res.json(await Supplier.create(req.body)));
app.put('/api/suppliers/:id', auth, async (req, res) => {
  await Supplier.update(req.body, { where: { id: req.params.id } });
  res.json(await Supplier.findByPk(req.params.id));
});

// CLIENTS
app.get('/api/clients', auth, async (req, res) => res.json(await Client.findAll()));
app.post('/api/clients', auth, async (req, res) => res.json(await Client.create(req.body)));
app.put('/api/clients/:id', auth, async (req, res) => {
  await Client.update(req.body, { where: { id: req.params.id } });
  res.json(await Client.findByPk(req.params.id));
});

// COMPONENTS
app.get('/api/components', auth, async (req, res) => res.json(await Component.findAll()));
app.post('/api/components', auth, async (req, res) => res.json(await Component.create(req.body)));
app.put('/api/components/:id', auth, async (req, res) => {
  await Component.update(req.body, { where: { id: req.params.id } });
  res.json(await Component.findByPk(req.params.id));
});

// RECIPES
app.get('/api/recipes', auth, async (req, res) => res.json(await Recipe.findAll()));
app.post('/api/recipes', auth, async (req, res) => {
  const recipe = await Recipe.create({ 
    name: req.body.name, 
    outputWeight: req.body.outputWeight, 
    outputUnit: req.body.outputUnit 
  });
  if (req.body.items) {
    for (const item of req.body.items) {
      await RecipeItem.create({ 
        recipeId: recipe.id, 
        componentId: item.componentId, 
        weight: item.weight,
        unit: item.unit 
      });
    }
  }
  res.json(recipe);
});

app.get('/api/recipes/:id', auth, async (req, res) => {
  const recipe = await Recipe.findByPk(req.params.id);
  const items = await RecipeItem.findAll({ 
    where: { recipeId: req.params.id }, 
    include: [Component] 
  });
  res.json({ ...recipe.toJSON(), items });
});

// PRODUCTS
app.get('/api/products', auth, async (req, res) => {
  const products = await Product.findAll({ include: [Recipe] });
  res.json(products);
});

app.post('/api/products', auth, async (req, res) => {
  const product = await Product.create(req.body);
  res.json(product);
});

app.put('/api/products/:id', auth, async (req, res) => {
  await Product.update(req.body, { where: { id: req.params.id } });
  res.json(await Product.findByPk(req.params.id));
});

app.get('/api/products/:id/prices', auth, async (req, res) => {
  const product = await Product.findByPk(req.params.id);
  const settings = await Settings.findOne();
  const prices = {
    base: parseFloat(product.basePrice),
    wholesale: parseFloat(product.basePrice) * (1 + settings.wholesaleMarkup / 100),
    retail1: parseFloat(product.basePrice) * (1 + settings.retail1Markup / 100),
    retail2: parseFloat(product.basePrice) * (1 + settings.retail2Markup / 100)
  };
  res.json(prices);
});

// PDF PRICE GENERATION
app.get('/api/products/price-pdf/:clientType', auth, (req, res) => {
  const { clientType } = req.params;
  
  Product.findAll().then(async products => {
    const settings = await Settings.findOne();
    
    let markup = 0;
    if (clientType === 'wholesale') markup = settings.wholesaleMarkup;
    if (clientType === 'retail1') markup = settings.retail1Markup;
    if (clientType === 'retail2') markup = settings.retail2Markup;
    
    const doc = new PDFDocument();
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=price-${clientType}.pdf`);
    doc.pipe(res);
    
    doc.fontSize(20).text('Прайс-лист Sazhenko Bakery', { align: 'center' });
    doc.moveDown();
    doc.fontSize(14).text(`Тип клієнта: ${clientType} (+${markup}%)`, { align: 'center' });
    doc.moveDown(2);
    
    products.forEach(p => {
      const price = parseFloat(p.basePrice) * (1 + markup / 100);
      doc.fontSize(12).text(`${p.name}: ${price.toFixed(2)} грн/коробка`);
    });
    
    doc.end();
  });
});

// ORDERS
app.get('/api/orders', auth, async (req, res) => {
  const orders = await Order.findAll({ include: [Client] });
  res.json(orders);
});

app.post('/api/orders', auth, async (req, res) => {
  const { clientId, items, notes } = req.body;
  const client = await Client.findByPk(clientId);
  const settings = await Settings.findOne();
  
  let markup = 0;
  if (client.type === 'wholesale') markup = settings.wholesaleMarkup;
  if (client.type === 'retail1') markup = settings.retail1Markup;
  if (client.type === 'retail2') markup = settings.retail2Markup;
  
  let totalBoxes = 0;
  let totalPrice = 0;
  
  const order = await Order.create({ clientId, notes });
  
  for (const item of items) {
    const product = await Product.findByPk(item.productId);
    const price = parseFloat(product.basePrice) * (1 + markup / 100) * item.boxes;
    await OrderItem.create({ orderId: order.id, productId: item.productId, boxes: item.boxes, price });
    totalBoxes += item.boxes;
    totalPrice += price;
  }
  
  order.totalBoxes = totalBoxes;
  order.totalPrice = totalPrice;
  await order.save();
  
  res.json(order);
});

app.put('/api/orders/:id/status', auth, async (req, res) => {
  await Order.update({ status: req.body.status }, { where: { id: req.params.id } });
  res.json(await Order.findByPk(req.params.id));
});

// ORDER PDF
app.get('/api/orders/:id/pdf', auth, async (req, res) => {
  const order = await Order.findByPk(req.params.id, { include: [Client] });
  const items = await OrderItem.findAll({ where: { orderId: req.params.id }, include: [Product] });
  
  const doc = new PDFDocument();
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `attachment; filename=order-${order.id}.pdf`);
  doc.pipe(res);
  
  doc.fontSize(20).text('Замовлення', { align: 'center' });
  doc.moveDown();
  doc.fontSize(14).text(`Клієнт: ${order.Client.name}`);
  doc.text(`Телефон: ${order.Client.phone}`);
  doc.moveDown();
  
  items.forEach(item => {
    doc.fontSize(12).text(`${item.Product.name} - ${item.boxes} коробок - ${item.price} грн`);
  });
  
  doc.moveDown();
  doc.fontSize(14).text(`Всього коробок: ${order.totalBoxes}`);
  doc.text(`Загальна сума: ${order.totalPrice} грн`);
  
  doc.end();
});

// ANALYTICS
app.get('/api/analytics/summary', auth, async (req, res) => {
  const { startDate, endDate } = req.query;
  
  let where = {};
  if (startDate && endDate) {
    where.createdAt = { [Sequelize.Op.between]: [new Date(startDate), new Date(endDate)] };
  }
  
  const totalOrders = await Order.count({ where });
  const openOrders = await Order.count({ where: { ...where, status: 'open' } });
  const completedOrders = await Order.count({ where: { ...where, status: 'completed' } });
  const totalRevenue = await Order.sum('totalPrice', { where });
  
  res.json({ totalOrders, openOrders, completedOrders, totalRevenue });
});

// SETTINGS
app.get('/api/settings', auth, async (req, res) => {
  let settings = await Settings.findOne();
  if (!settings) settings = await Settings.create({});
  res.json(settings);
});

app.put('/api/settings', auth, async (req, res) => {
  let settings = await Settings.findOne();
  if (!settings) {
    settings = await Settings.create(req.body);
  } else {
    await settings.update(req.body);
  }
  res.json(settings);
});

// INIT
sequelize.sync({ force: true }).then(async () => {
  const hashed = await bcrypt.hash('admin', 10);
  await User.create({ login: 'admin', password: hashed, name: 'Administrator', role: 'admin' });
  await Settings.create({});
  console.log('✅ Database initialized');
  app.listen(3000, () => console.log('🚀 Backend on :3000'));
});
EOF

echo "✅ Backend создан"
echo ""
echo "Создаю frontend..."
echo ""

# Frontend files будут в следующем сообщении из-за ограничения размера

cat > .gitignore << 'EOF'
node_modules
.env
/frontend/build
pgdata
*.log
EOF

cat > README.md << 'EOF'
# 🍰 Bakery ERP v3.2

## Новые возможности v3.2
- ✅ Страница заказов (привязка товаров к клиентам)
- ✅ Генерация PDF для заказов
- ✅ Генерация прайс-листа в PDF
- ✅ Аналитика (статистика заказов, сводки)
- ✅ Telegram ссылки (автоматические)
- ✅ Рецепты: выбор единиц (кг/г/мл)
- ✅ Товары: редактирование, автогенерация веса

## Запуск
```bash
chmod +x install-v3.2.sh
./install-v3.2.sh
docker compose down --volumes
docker compose up -d --build
```

**Логин:** admin / **Пароль:** admin  
**URL:** http://localhost
EOF

echo ""
echo "✅ v3.2 создана!"
echo ""
echo "⚠️  Файлы frontend создаются отдельным скриптом"
echo "   (слишком большой размер для одного файла)"
echo ""
