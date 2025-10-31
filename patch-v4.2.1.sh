#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.2.1 PATCH
# Упаковка в товаре + Списание со склада при выполнении заказа
###############################################################################

set -e

echo "🍰 Bakery ERP v4.2.1 PATCH"
echo "=========================="
echo ""
echo "Добавляет:"
echo "  ✅ Упаковку в товар (отдельно от рецепта)"
echo "  ✅ Закупки упаковки"
echo "  ✅ Автоматическое списание со склада при выполнении заказа"
echo "  ✅ MRP расчёт по всем уровням рецептов"
echo ""

###############################################################################
# BACKEND - ENHANCED server.js WITH STOCK WRITEOFF
###############################################################################

cat > backend/src/server.js << 'EOFSERVER'
import express from 'express';
import cors from 'cors';
import { Sequelize, DataTypes, Op } from 'sequelize';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const app = express();
app.use(cors());
app.use(express.json());

const sequelize = new Sequelize(process.env.DATABASE_URL, { logging: false });

// ============================================================================
// MODELS
// ============================================================================

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
  type: { 
    type: DataTypes.STRING,
    defaultValue: 'RAW'
  },
  unit: { type: DataTypes.STRING, defaultValue: 'кг' },
  linkedRecipeId: { type: DataTypes.INTEGER, allowNull: true }
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
  name: DataTypes.STRING,
  outputWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 1.000 },
  calculatedCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const RecipeItem = sequelize.define('RecipeItem', {
  recipeId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  weight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  stage: { type: DataTypes.STRING, defaultValue: 'основа' }
});

// ENHANCED Product - добавляем упаковку
const Product = sequelize.define('Product', {
  name: DataTypes.STRING,
  recipeId: { type: DataTypes.INTEGER },
  packagingComponentId: { 
    type: DataTypes.INTEGER, 
    allowNull: true,
    comment: 'ID компонента упаковки (PACK)'
  },
  packagingQty: { 
    type: DataTypes.DECIMAL(10, 3), 
    defaultValue: 1,
    comment: 'Количество упаковки на 1 коробку'
  },
  boxNetWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 1.000 },
  boxGrossWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 1.000 },
  calculatedCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  wholesalePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  retail1Price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  retail2Price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Order = sequelize.define('Order', {
  orderNumber: DataTypes.STRING,
  clientId: DataTypes.INTEGER,
  status: { 
    type: DataTypes.ENUM('draft', 'in_production', 'done'), 
    defaultValue: 'draft' 
  },
  totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  totalCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  profit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const OrderItem = sequelize.define('OrderItem', {
  orderId: DataTypes.INTEGER,
  productId: DataTypes.INTEGER,
  boxes: { type: DataTypes.INTEGER, defaultValue: 1 },
  unitPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

// Production usage log
const ProductionUsage = sequelize.define('ProductionUsage', {
  orderId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  qtyUsed: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  costPerUnit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  totalCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Settings = sequelize.define('Settings', {
  wholesaleMarkup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 10 },
  retail1Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 40 },
  retail2Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 70 },
  laborCostPercent: { type: DataTypes.DECIMAL(5, 2), defaultValue: 10 },
  overheadPercent: { type: DataTypes.DECIMAL(5, 2), defaultValue: 5 },
  companyName: { type: DataTypes.STRING, defaultValue: 'Sazhenko Bakery' }
});

// ============================================================================
// ASSOCIATIONS
// ============================================================================

Order.belongsTo(Client, { foreignKey: 'clientId' });
Order.hasMany(OrderItem, { foreignKey: 'orderId' });
Order.hasMany(ProductionUsage, { foreignKey: 'orderId' });
OrderItem.belongsTo(Order, { foreignKey: 'orderId' });
OrderItem.belongsTo(Product, { foreignKey: 'productId' });
Stock.belongsTo(Component, { foreignKey: 'componentId' });
Purchase.belongsTo(Supplier, { foreignKey: 'supplierId' });
Purchase.belongsTo(Component, { foreignKey: 'componentId' });
Recipe.hasMany(RecipeItem, { foreignKey: 'recipeId' });
RecipeItem.belongsTo(Recipe, { foreignKey: 'recipeId' });
RecipeItem.belongsTo(Component, { foreignKey: 'componentId' });
Product.belongsTo(Recipe, { foreignKey: 'recipeId' });
Product.belongsTo(Component, { as: 'PackagingComponent', foreignKey: 'packagingComponentId' });
Component.belongsTo(Recipe, { as: 'LinkedRecipe', foreignKey: 'linkedRecipeId' });
ProductionUsage.belongsTo(Component, { foreignKey: 'componentId' });

// ============================================================================
// COST CALCULATION FUNCTIONS
// ============================================================================

async function calculateComponentCost(componentId, visited = new Set()) {
  if (visited.has(componentId)) return 0;
  visited.add(componentId);

  const component = await Component.findByPk(componentId);
  if (!component) return 0;

  if (component.type !== 'SEMI_OWN') {
    const stock = await Stock.findOne({ where: { componentId } });
    return stock ? parseFloat(stock.avgCost) : 0;
  }

  if (component.linkedRecipeId) {
    return await calculateRecipeCost(component.linkedRecipeId, visited);
  }

  return 0;
}

async function calculateRecipeCost(recipeId, visited = new Set()) {
  const recipe = await Recipe.findByPk(recipeId, {
    include: [{ model: RecipeItem, include: [Component] }]
  });

  if (!recipe || !recipe.RecipeItems) return 0;

  let totalCost = 0;

  for (const item of recipe.RecipeItems) {
    const componentCost = await calculateComponentCost(item.componentId, visited);
    const itemCost = parseFloat(item.weight) * componentCost;
    totalCost += itemCost;
  }

  const outputWeight = parseFloat(recipe.outputWeight) || 1;
  const costPer1Kg = totalCost / outputWeight;

  await recipe.update({ calculatedCost: costPer1Kg });

  return costPer1Kg;
}

async function calculateProductCost(productId) {
  const product = await Product.findByPk(productId);
  if (!product || !product.recipeId) return 0;

  const recipeCostPer1Kg = await calculateRecipeCost(product.recipeId);
  const boxNetWeight = parseFloat(product.boxNetWeight) || 1;
  
  let baseCost = recipeCostPer1Kg * boxNetWeight;

  // Добавляем стоимость упаковки
  if (product.packagingComponentId) {
    const packCost = await calculateComponentCost(product.packagingComponentId);
    const packQty = parseFloat(product.packagingQty) || 1;
    baseCost += packCost * packQty;
  }

  const settings = await Settings.findOne();
  if (settings) {
    const laborPercent = parseFloat(settings.laborCostPercent) || 0;
    const overheadPercent = parseFloat(settings.overheadPercent) || 0;
    baseCost = baseCost * (1 + (laborPercent + overheadPercent) / 100);
  }

  const wholesaleMarkup = settings ? parseFloat(settings.wholesaleMarkup) : 10;
  const retail1Markup = settings ? parseFloat(settings.retail1Markup) : 40;
  const retail2Markup = settings ? parseFloat(settings.retail2Markup) : 70;

  const wholesalePrice = baseCost * (1 + wholesaleMarkup / 100);
  const retail1Price = baseCost * (1 + retail1Markup / 100);
  const retail2Price = baseCost * (1 + retail2Markup / 100);

  await product.update({
    calculatedCost: baseCost,
    wholesalePrice,
    retail1Price,
    retail2Price
  });

  return { baseCost, wholesalePrice, retail1Price, retail2Price };
}

// ============================================================================
// MRP - Material Requirements Planning
// ============================================================================

// Рекурсивный сбор всех сырьевых компонентов для рецепта
async function collectRawMaterials(recipeId, multiplier = 1, materials = {}, visited = new Set()) {
  if (visited.has(recipeId)) return materials;
  visited.add(recipeId);

  const recipe = await Recipe.findByPk(recipeId, {
    include: [{ model: RecipeItem, include: [Component] }]
  });

  if (!recipe || !recipe.RecipeItems) return materials;

  for (const item of recipe.RecipeItems) {
    const component = item.Component;
    const qty = parseFloat(item.weight) * multiplier;

    if (component.type === 'SEMI_OWN' && component.linkedRecipeId) {
      // Рекурсивно разворачиваем вложенный рецепт
      await collectRawMaterials(component.linkedRecipeId, qty, materials, visited);
    } else {
      // RAW, SEMI_BOUGHT, PACK - добавляем в список
      if (!materials[component.id]) {
        materials[component.id] = {
          componentId: component.id,
          name: component.name,
          type: component.type,
          unit: component.unit,
          qty: 0
        };
      }
      materials[component.id].qty += qty;
    }
  }

  return materials;
}

// Списание со склада
async function writeOffStock(orderId) {
  const order = await Order.findByPk(orderId, {
    include: [{ 
      model: OrderItem, 
      include: [{ 
        model: Product, 
        include: [Recipe, { model: Component, as: 'PackagingComponent' }]
      }] 
    }]
  });

  if (!order || !order.OrderItems) return { error: 'Order not found' };

  const allMaterials = {};

  // Собираем материалы по всем позициям заказа
  for (const orderItem of order.OrderItems) {
    const product = orderItem.Product;
    const boxes = parseInt(orderItem.boxes);
    const boxNetWeight = parseFloat(product.boxNetWeight) || 1;
    const totalWeight = boxNetWeight * boxes;

    // Материалы из рецепта
    if (product.recipeId) {
      await collectRawMaterials(product.recipeId, totalWeight, allMaterials);
    }

    // Упаковка
    if (product.packagingComponentId) {
      const packQty = parseFloat(product.packagingQty) || 1;
      const totalPackQty = packQty * boxes;

      if (!allMaterials[product.packagingComponentId]) {
        const packComp = product.PackagingComponent;
        allMaterials[product.packagingComponentId] = {
          componentId: product.packagingComponentId,
          name: packComp?.name || 'Упаковка',
          type: 'PACK',
          unit: packComp?.unit || 'шт',
          qty: 0
        };
      }
      allMaterials[product.packagingComponentId].qty += totalPackQty;
    }
  }

  // Списываем со склада и логируем
  let totalCost = 0;

  for (const mat of Object.values(allMaterials)) {
    const stock = await Stock.findOne({ where: { componentId: mat.componentId } });
    
    if (!stock) {
      console.warn(\`Component \${mat.name} not in stock\`);
      continue;
    }

    const currentQty = parseFloat(stock.qtyOnHand);
    const costPerUnit = parseFloat(stock.avgCost);
    const usedQty = parseFloat(mat.qty);
    const cost = usedQty * costPerUnit;

    // Списываем
    const newQty = Math.max(0, currentQty - usedQty);
    await stock.update({ qtyOnHand: newQty });

    // Логируем
    await ProductionUsage.create({
      orderId,
      componentId: mat.componentId,
      qtyUsed: usedQty,
      costPerUnit,
      totalCost: cost
    });

    totalCost += cost;
  }

  // Обновляем заказ
  await order.update({
    status: 'done',
    totalCost,
    profit: parseFloat(order.totalPrice) - totalCost
  });

  return { 
    success: true, 
    materials: Object.values(allMaterials),
    totalCost,
    profit: parseFloat(order.totalPrice) - totalCost
  };
}

// ============================================================================
// AUTH
// ============================================================================

const auth = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    jwt.verify(token, 'my-secret-key-2024');
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

// ============================================================================
// ROUTES
// ============================================================================

// Auth
app.post('/api/auth/login', async (req, res) => {
  const { login, password } = req.body;
  const user = await User.findOne({ where: { login } });
  if (!user || !await bcrypt.compare(password, user.password)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  const token = jwt.sign({ id: user.id }, 'my-secret-key-2024', { expiresIn: '8h' });
  res.json({ token, user: { id: user.id, login: user.login, name: user.name } });
});

// Users
app.get('/api/users', auth, async (req, res) => {
  res.json(await User.findAll({ attributes: { exclude: ['password'] } }));
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

// Clients
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

// Suppliers
app.get('/api/suppliers', auth, async (req, res) => res.json(await Supplier.findAll()));
app.post('/api/suppliers', auth, async (req, res) => res.json(await Supplier.create(req.body)));

// Components
app.get('/api/components', auth, async (req, res) => {
  res.json(await Component.findAll({
    include: [{ model: Recipe, as: 'LinkedRecipe' }]
  }));
});
app.post('/api/components', auth, async (req, res) => {
  res.json(await Component.create(req.body));
});

// Purchases
app.get('/api/purchases', auth, async (req, res) => {
  res.json(await Purchase.findAll({ 
    include: [Supplier, Component],
    order: [['date', 'DESC']]
  }));
});
app.post('/api/purchases', auth, async (req, res) => {
  const { supplierId, componentId, qty, pricePerUnit } = req.body;
  const totalSum = parseFloat(qty) * parseFloat(pricePerUnit);
  
  const purchase = await Purchase.create({ ...req.body, totalSum });
  
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

// Stock
app.get('/api/stock', auth, async (req, res) => {
  res.json(await Stock.findAll({ include: [Component] }));
});

// Recipes
app.get('/api/recipes', auth, async (req, res) => {
  const recipes = await Recipe.findAll({ 
    include: [{ model: RecipeItem, include: [Component] }] 
  });
  res.json(recipes);
});

app.post('/api/recipes', auth, async (req, res) => {
  const recipe = await Recipe.create(req.body);
  if (req.body.items) {
    for (const item of req.body.items) {
      await RecipeItem.create({ recipeId: recipe.id, ...item });
    }
  }
  await calculateRecipeCost(recipe.id);
  res.json(await Recipe.findByPk(recipe.id, { 
    include: [{ model: RecipeItem, include: [Component] }] 
  }));
});

app.put('/api/recipes/:id', auth, async (req, res) => {
  const { name, outputWeight, items } = req.body;
  await Recipe.update({ name, outputWeight }, { where: { id: req.params.id } });
  
  if (items) {
    await RecipeItem.destroy({ where: { recipeId: req.params.id } });
    for (const item of items) {
      await RecipeItem.create({ recipeId: req.params.id, ...item });
    }
  }
  
  await calculateRecipeCost(req.params.id);
  
  res.json(await Recipe.findByPk(req.params.id, { 
    include: [{ model: RecipeItem, include: [Component] }] 
  }));
});

app.get('/api/recipes/:id/cost', auth, async (req, res) => {
  const cost = await calculateRecipeCost(req.params.id);
  res.json({ recipeCostPer1Kg: cost });
});

// Products
app.get('/api/products', auth, async (req, res) => {
  res.json(await Product.findAll({ 
    include: [Recipe, { model: Component, as: 'PackagingComponent' }] 
  }));
});

app.post('/api/products', auth, async (req, res) => {
  const product = await Product.create(req.body);
  if (product.recipeId) {
    await calculateProductCost(product.id);
  }
  res.json(await Product.findByPk(product.id, { 
    include: [Recipe, { model: Component, as: 'PackagingComponent' }] 
  }));
});

app.put('/api/products/:id', auth, async (req, res) => {
  await Product.update(req.body, { where: { id: req.params.id } });
  if (req.body.recipeId || req.body.boxNetWeight || req.body.packagingComponentId) {
    await calculateProductCost(req.params.id);
  }
  res.json(await Product.findByPk(req.params.id, { 
    include: [Recipe, { model: Component, as: 'PackagingComponent' }] 
  }));
});

app.post('/api/products/:id/recalculate', auth, async (req, res) => {
  const costs = await calculateProductCost(req.params.id);
  res.json(costs);
});

// Orders
app.get('/api/orders', auth, async (req, res) => {
  res.json(await Order.findAll({ 
    include: [Client, { model: OrderItem, include: [Product] }],
    order: [['createdAt', 'DESC']]
  }));
});

app.post('/api/orders', auth, async (req, res) => {
  const order = await Order.create(req.body);
  res.json(order);
});

app.put('/api/orders/:id', auth, async (req, res) => {
  await Order.update(req.body, { where: { id: req.params.id } });
  res.json(await Order.findByPk(req.params.id));
});

app.post('/api/orders/:id/items', auth, async (req, res) => {
  const item = await OrderItem.create({ orderId: req.params.id, ...req.body });
  res.json(item);
});

// ENHANCED: Complete order with stock writeoff
app.post('/api/orders/:id/complete', auth, async (req, res) => {
  try {
    const result = await writeOffStock(req.params.id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get production usage for order
app.get('/api/orders/:id/usage', auth, async (req, res) => {
  const usage = await ProductionUsage.findAll({
    where: { orderId: req.params.id },
    include: [Component]
  });
  res.json(usage);
});

// Settings
app.get('/api/settings', auth, async (req, res) => {
  let settings = await Settings.findOne();
  if (!settings) {
    settings = await Settings.create({});
  }
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

// ============================================================================
// INIT
// ============================================================================

const init = async () => {
  await sequelize.sync({ force: false, alter: true });
  
  const admin = await User.findOne({ where: { login: 'admin' } });
  if (!admin) {
    const hashed = await bcrypt.hash('admin', 10);
    await User.create({ 
      login: 'admin', 
      password: hashed, 
      name: 'Administrator', 
      role: 'admin' 
    });
  }

  let settings = await Settings.findOne();
  if (!settings) {
    await Settings.create({});
  }
  
  console.log('✅ Database ready (v4.2.1)');
  app.listen(3000, '0.0.0.0', () => console.log('🚀 Backend v4.2.1 on :3000'));
};

init().catch(err => {
  console.error('❌ Init failed:', err);
  process.exit(1);
});
EOFSERVER

echo ""
echo "✅ Патч v4.2.1 применён!"
echo ""
echo "📋 Что добавлено:"
echo "   ✅ Product.packagingComponentId - ID упаковки"
echo "   ✅ Product.packagingQty - количество упаковки на коробку"
echo "   ✅ Упаковку можно закупать (тип PACK)"
echo "   ✅ POST /api/orders/:id/complete - списание со склада"
echo "   ✅ GET /api/orders/:id/usage - журнал списания"
echo "   ✅ MRP расчёт по всем уровням рецептов"
echo ""
echo "🚀 Перезапустите:"
echo "   docker compose down"
echo "   docker compose up -d --build"
echo ""
