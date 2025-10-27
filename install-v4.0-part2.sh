#!/bin/bash

###############################################################################
# Sazhenko Bakery ERP v4.0 - Part 2
# Продолжение backend API (Recipes, Products, Orders, Production)
###############################################################################

set -e

echo "🍰 Bakery ERP v4.0 - Part 2"
echo "============================"
echo ""

# Продолжаем server.js
cat >> backend/server.js << 'EOF'

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
EOF

echo "✅ Backend v4.0 Part 2 завершён!"
echo ""
