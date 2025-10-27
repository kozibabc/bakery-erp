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

// ============================================================================
// PRICE HISTORY
// ============================================================================

app.get('/api/price-history/:componentId', auth, async (req, res) => {
  const history = await PriceHistory.findAll({
    where: { componentId: req.params.componentId },
    order: [['date', 'DESC']],
    limit: 50
  });
  res.json(history);
});

// ============================================================================
// RECIPES
// ============================================================================

app.get('/api/recipes', auth, async (req, res) => res.json(await Recipe.findAll()));

app.post('/api/recipes', auth, async (req, res) => {
  try {
    const recipe = await Recipe.create({ 
      name: req.body.name, 
      outputWeight: sanitizeNumeric(req.body.outputWeight) || 1, 
      outputUnit: req.body.outputUnit || 'кг'
    });
    if (req.body.items) {
      for (const item of req.body.items) {
        await RecipeItem.create({ 
          recipeId: recipe.id, 
          componentId: item.componentId, 
          weight: sanitizeNumeric(item.weight),
          unit: item.unit || 'кг'
        });
      }
    }
    res.json(recipe);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.get('/api/recipes/:id', auth, async (req, res) => {
  const recipe = await Recipe.findByPk(req.params.id);
  const items = await RecipeItem.findAll({ 
    where: { recipeId: req.params.id }, 
    include: [Component] 
  });
  res.json({ ...recipe.toJSON(), items });
});

// ============================================================================
// PRODUCTS (SKU)
// ============================================================================

app.get('/api/products', auth, async (req, res) => {
  const products = await Product.findAll({ include: [Recipe] });
  res.json(products);
});

app.post('/api/products', auth, async (req, res) => {
  try {
    const settings = await Settings.findOne();
    const basePrice = sanitizeNumeric(req.body.basePrice);
    
    const data = {
      name: req.body.name,
      code: req.body.code,
      recipeId: req.body.recipeId,
      boxGrossWeight: sanitizeNumeric(req.body.boxGrossWeight),
      boxNetWeight: sanitizeNumeric(req.body.boxNetWeight),
      basePrice: basePrice,
      retail1Price: req.body.retail1Price || (basePrice * (1 + settings.retail1Markup / 100)),
      retail2Price: req.body.retail2Price || (basePrice * (1 + settings.retail2Markup / 100))
    };
    const product = await Product.create(data);
    res.json(product);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

app.put('/api/products/:id', auth, async (req, res) => {
  try {
    const settings = await Settings.findOne();
    const basePrice = sanitizeNumeric(req.body.basePrice);
    
    const data = {
      name: req.body.name,
      code: req.body.code,
      recipeId: req.body.recipeId,
      boxGrossWeight: sanitizeNumeric(req.body.boxGrossWeight),
      boxNetWeight: sanitizeNumeric(req.body.boxNetWeight),
      basePrice: basePrice,
      retail1Price: req.body.retail1Price || (basePrice * (1 + settings.retail1Markup / 100)),
      retail2Price: req.body.retail2Price || (basePrice * (1 + settings.retail2Markup / 100))
    };
    await Product.update(data, { where: { id: req.params.id } });
    res.json(await Product.findByPk(req.params.id));
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ============================================================================
// ORDERS
// ============================================================================

app.get('/api/orders', auth, async (req, res) => {
  const orders = await Order.findAll({ 
    include: [Client],
    order: [['createdAt', 'DESC']]
  });
  res.json(orders);
});

app.post('/api/orders', auth, async (req, res) => {
  try {
    const { clientId, items, notes } = req.body;
    const client = await Client.findByPk(clientId);
    
    let totalBoxes = 0;
    let totalPrice = 0;
    
    // Генерация номера заказа
    const orderNumber = `ORD-${Date.now()}`;
    
    const order = await Order.create({ 
      orderNumber,
      clientId, 
      notes,
      status: 'draft'
    });
    
    for (const item of items) {
      const product = await Product.findByPk(item.productId);
      
      // Выбираем цену по типу клиента
      let unitPrice = parseFloat(product.basePrice);
      if (client.type === 'retail1') unitPrice = parseFloat(product.retail1Price);
      if (client.type === 'retail2') unitPrice = parseFloat(product.retail2Price);
      
      const itemTotal = unitPrice * item.boxes;
      
      await OrderItem.create({ 
        orderId: order.id, 
        productId: item.productId, 
        boxes: item.boxes, 
        unitPrice,
        totalPrice: itemTotal
      });
      
      totalBoxes += item.boxes;
      totalPrice += itemTotal;
    }
    
    order.totalBoxes = totalBoxes;
    order.totalPrice = totalPrice;
    await order.save();
    
    res.json(order);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ============================================================================
// START PRODUCTION (СПИСАНИЕ СО СКЛАДА)
// ============================================================================

app.post('/api/orders/:id/start-production', auth, async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.id);
    if (order.status !== 'draft' && order.status !== 'confirmed') {
      return res.status(400).json({ error: 'Order already in production' });
    }
    
    const orderItems = await OrderItem.findAll({ 
      where: { orderId: order.id },
      include: [Product]
    });
    
    let totalCost = 0;
    const usageMap = {}; // componentId -> { qty, cost }
    
    // Рассчитываем MRP для всех товаров
    for (const item of orderItems) {
      const product = item.Product;
      const recipe = await Recipe.findByPk(product.recipeId);
      const recipeItems = await RecipeItem.findAll({ 
        where: { recipeId: recipe.id },
        include: [Component]
      });
      
      // Для каждого компонента в рецепте
      for (const recipeItem of recipeItems) {
        const componentId = recipeItem.componentId;
        const qtyPerBox = parseFloat(recipeItem.weight) * parseFloat(product.boxNetWeight) / parseFloat(recipe.outputWeight);
        const totalQty = qtyPerBox * item.boxes;
        
        if (!usageMap[componentId]) {
          usageMap[componentId] = { qty: 0, cost: 0 };
        }
        usageMap[componentId].qty += totalQty;
      }
    }
    
    // Списываем со склада и считаем стоимость
    for (const [componentId, usage] of Object.entries(usageMap)) {
      const stock = await Stock.findOne({ where: { componentId } });
      
      if (parseFloat(stock.qtyOnHand) < usage.qty) {
        return res.status(400).json({ 
          error: `Insufficient stock for component ID ${componentId}. Need ${usage.qty}, have ${stock.qtyOnHand}` 
        });
      }
      
      const avgCost = parseFloat(stock.avgCost);
      const costForThis = usage.qty * avgCost;
      
      // Списываем со склада
      await stock.update({
        qtyOnHand: parseFloat(stock.qtyOnHand) - usage.qty
      });
      
      // Записываем использование
      await ProductionUsage.create({
        orderId: order.id,
        componentId: componentId,
        qtyUsed: usage.qty,
        unit: (await Component.findByPk(componentId)).unit,
        costPerUnit: avgCost,
        totalCost: costForThis
      });
      
      totalCost += costForThis;
    }
    
    // Обновляем заказ
    const profit = parseFloat(order.totalPrice) - totalCost;
    await order.update({
      status: 'in_production',
      costOfGoods: totalCost,
      profit: profit
    });
    
    res.json({ 
      message: 'Production started', 
      order,
      costOfGoods: totalCost,
      profit: profit
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/orders/:id/status', auth, async (req, res) => {
  await Order.update({ status: req.body.status }, { where: { id: req.params.id } });
  res.json(await Order.findByPk(req.params.id));
});

// ============================================================================
// ORDER PDF
// ============================================================================

app.get('/api/orders/:id/pdf', auth, async (req, res) => {
  const order = await Order.findByPk(req.params.id, { include: [Client] });
  const items = await OrderItem.findAll({ 
    where: { orderId: req.params.id }, 
    include: [Product] 
  });
  
  const doc = new PDFDocument({ margin: 50 });
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `attachment; filename=order-${order.orderNumber}.pdf`);
  doc.pipe(res);
  
  // Заголовок
  doc.fontSize(24).text('Замовлення', { align: 'center' });
  doc.fontSize(14).text(`№ ${order.orderNumber}`, { align: 'center' });
  doc.moveDown();
  
  // Информация о клиенте
  doc.fontSize(12).text(`Клієнт: ${order.Client.name}`);
  doc.text(`Телефон: ${order.Client.phone || 'н/д'}`);
  doc.text(`Email: ${order.Client.email || 'н/д'}`);
  doc.text(`Дата: ${new Date(order.createdAt).toLocaleDateString('uk-UA')}`);
  doc.moveDown();
  
  // Таблица товаров
  doc.fontSize(14).text('Товари:', { underline: true });
  doc.moveDown(0.5);
  
  items.forEach(item => {
    doc.fontSize(11).text(
      `${item.Product.name} - ${item.boxes} коробок × ${item.unitPrice} грн = ${item.totalPrice} грн`
    );
  });
  
  doc.moveDown();
  doc.fontSize(12).text(`Всього коробок: ${order.totalBoxes}`);
  doc.fontSize(14).text(`Загальна сума: ${order.totalPrice} грн`, { bold: true });
  
  if (order.notes) {
    doc.moveDown();
    doc.fontSize(10).text(`Примітки: ${order.notes}`);
  }
  
  doc.end();
});

// ============================================================================
// PRICE LISTS PDF
// ============================================================================

app.get('/api/pricelist/pdf/:type', auth, async (req, res) => {
  try {
    const { type } = req.params; // wholesale, retail1, retail2
    const products = await Product.findAll();
    const settings = await Settings.findOne();
    
    const doc = new PDFDocument({ margin: 50 });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=pricelist-${type}.pdf`);
    doc.pipe(res);
    
    // Заголовок
    doc.fontSize(20).text(settings.companyName || 'Sazhenko Bakery', { align: 'center' });
    doc.moveDown();
    
    let typeLabel = 'ОПТ';
    if (type === 'retail1') typeLabel = 'Роздріб 1';
    if (type === 'retail2') typeLabel = 'Роздріб 2';
    
    doc.fontSize(16).text(`Прайс-лист (${typeLabel})`, { align: 'center' });
    doc.fontSize(10).text(`Дата: ${new Date().toLocaleDateString('uk-UA')}`, { align: 'center' });
    doc.moveDown(2);
    
    // Таблица
    doc.fontSize(11).text('Товар', 50, doc.y, { continued: true, width: 200 });
    doc.text('Вага', 270, doc.y, { continued: true, width: 80 });
    doc.text('Ціна/кг', 360, doc.y, { continued: true, width: 80 });
    doc.text('Ціна/коробка', 450, doc.y, { width: 100 });
    doc.moveDown();
    doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke();
    doc.moveDown(0.5);
    
    products.forEach(p => {
      let price = parseFloat(p.basePrice);
      if (type === 'retail1') price = parseFloat(p.retail1Price);
      if (type === 'retail2') price = parseFloat(p.retail2Price);
      
      const weight = parseFloat(p.boxNetWeight);
      const pricePerKg = weight > 0 ? (price / weight).toFixed(2) : '0.00';
      
      doc.fontSize(10).text(p.name, 50, doc.y, { continued: true, width: 200 });
      doc.text(`${weight} кг`, 270, doc.y, { continued: true, width: 80 });
      doc.text(`${pricePerKg} грн`, 360, doc.y, { continued: true, width: 80 });
      doc.text(`${price.toFixed(2)} грн`, 450, doc.y, { width: 100 });
      doc.moveDown(0.7);
    });
    
    // Подвал
    doc.moveDown();
    doc.fontSize(9).text(settings.priceListFooter || 'Ціни дійсні на момент формування', { align: 'center' });
    doc.text('Sazhenko Bakery - виробництво випічки з любов\'ю', { align: 'center', italics: true });
    
    doc.end();
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================================
// PRICE LISTS EXCEL
// ============================================================================

app.get('/api/pricelist/excel/:type', auth, async (req, res) => {
  try {
    const { type } = req.params;
    const products = await Product.findAll();
    
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Прайс-лист');
    
    // Заголовки
    worksheet.columns = [
      { header: '№', key: 'num', width: 5 },
      { header: 'Товар', key: 'name', width: 30 },
      { header: 'Вага (кг)', key: 'weight', width: 12 },
      { header: 'Ціна/кг', key: 'pricePerKg', width: 12 },
      { header: 'Ціна/коробка', key: 'pricePerBox', width: 15 }
    ];
    
    // Данные
    products.forEach((p, idx) => {
      let price = parseFloat(p.basePrice);
      if (type === 'retail1') price = parseFloat(p.retail1Price);
      if (type === 'retail2') price = parseFloat(p.retail2Price);
      
      const weight = parseFloat(p.boxNetWeight);
      const pricePerKg = weight > 0 ? (price / weight).toFixed(2) : '0.00';
      
      worksheet.addRow({
        num: idx + 1,
        name: p.name,
        weight: weight,
        pricePerKg: pricePerKg,
        pricePerBox: price.toFixed(2)
      });
    });
    
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=pricelist-${type}.xlsx`);
    
    await workbook.xlsx.write(res);
    res.end();
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================================
// ANALYTICS
// ============================================================================

app.get('/api/analytics/summary', auth, async (req, res) => {
  const { startDate, endDate } = req.query;
  
  let where = {};
  if (startDate && endDate) {
    where.createdAt = { [Op.between]: [new Date(startDate), new Date(endDate)] };
  }
  
  const totalOrders = await Order.count({ where });
  const openOrders = await Order.count({ where: { ...where, status: { [Op.in]: ['draft', 'confirmed'] } } });
  const inProductionOrders = await Order.count({ where: { ...where, status: 'in_production' } });
  const completedOrders = await Order.count({ where: { ...where, status: 'done' } });
  const totalRevenue = await Order.sum('totalPrice', { where: { ...where, status: 'done' } }) || 0;
  const totalCost = await Order.sum('costOfGoods', { where: { ...where, status: 'done' } }) || 0;
  const totalProfit = totalRevenue - totalCost;
  
  res.json({ 
    totalOrders, 
    openOrders, 
    inProductionOrders,
    completedOrders, 
    totalRevenue,
    totalCost,
    totalProfit
  });
});

// ============================================================================
// SETTINGS
// ============================================================================

app.get('/api/settings', auth, async (req, res) => {
  let settings = await Settings.findOne();
  if (!settings) settings = await Settings.create({});
  res.json(settings);
});

app.put('/api/settings', auth, async (req, res) => {
  try {
    const data = {
      wholesaleMarkup: sanitizeNumeric(req.body.wholesaleMarkup),
      retail1Markup: sanitizeNumeric(req.body.retail1Markup),
      retail2Markup: sanitizeNumeric(req.body.retail2Markup),
      companyName: req.body.companyName,
      companyLogo: req.body.companyLogo,
      priceListFooter: req.body.priceListFooter
    };
    let settings = await Settings.findOne();
    if (!settings) {
      settings = await Settings.create(data);
    } else {
      await settings.update(data);
    }
    res.json(settings);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ============================================================================
// INIT & START
// ============================================================================

const initDB = async () => {
  await sequelize.sync({ force: false, alter: true });
  
  // Проверяем наличие админа
  const adminExists = await User.findOne({ where: { login: 'admin' } });
  if (!adminExists) {
    const hashed = await bcrypt.hash('admin', 10);
    const admin = await User.create({ 
      login: 'admin', 
      password: hashed, 
      name: 'Administrator', 
      role: 'admin' 
    });
    await Permission.create({ 
      userId: admin.id,
      canViewStock: true,
      canEditStock: true,
      canAddPurchases: true,
      canStartProduction: true,
      canViewFinances: true,
      canEditSettings: true,
      canManageUsers: true
    });
  }
  
  // Проверяем наличие настроек
  const settingsExist = await Settings.findOne();
  if (!settingsExist) {
    await Settings.create({});
  }
  
  console.log('✅ Database initialized');
};

initDB().then(() => {
  app.listen(3000, () => console.log('🚀 Backend v4.0 on :3000'));
}).catch(err => {
  console.error('❌ Database init failed:', err);
  process.exit(1);
});
