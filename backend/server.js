import express from 'express';
import cors from 'cors';
import { Sequelize, DataTypes } from 'sequelize';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

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
  outputWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 1 }
});

const RecipeItem = sequelize.define('RecipeItem', {
  recipeId: DataTypes.INTEGER,
  componentId: DataTypes.INTEGER,
  weight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 }
});

const Product = sequelize.define('Product', {
  name: DataTypes.STRING,
  recipeId: DataTypes.INTEGER,
  boxGrossWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  boxNetWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
  basePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
});

const Settings = sequelize.define('Settings', {
  wholesaleMarkup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 10 },
  retail1Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 40 },
  retail2Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 70 }
});

// ASSOCIATIONS
RecipeItem.belongsTo(Component, { foreignKey: 'componentId' });

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
  if (password) {
    user.password = await bcrypt.hash(password, 10);
  }
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
  const recipe = await Recipe.create({ name: req.body.name, outputWeight: req.body.outputWeight });
  if (req.body.items) {
    for (const item of req.body.items) {
      await RecipeItem.create({ recipeId: recipe.id, componentId: item.componentId, weight: item.weight });
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
  const products = await Product.findAll();
  res.json(products);
});

app.post('/api/products', auth, async (req, res) => {
  const product = await Product.create(req.body);
  res.json(product);
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

// SETTINGS
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

// INIT
sequelize.sync({ force: true }).then(async () => {
  const hashed = await bcrypt.hash('admin', 10);
  await User.create({ login: 'admin', password: hashed, name: 'Administrator', role: 'admin' });
  await Settings.create({});
  console.log('✅ Database initialized');
  app.listen(3000, () => console.log('🚀 Backend on :3000'));
});
