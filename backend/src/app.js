import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import db from './db.js';
import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import productRoutes from './routes/products.js';
import clientRoutes from './routes/clients.js';
import supplierRoutes from './routes/suppliers.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (_, res) => res.json({ ok: true }));
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/suppliers', supplierRoutes);

db.sync().then(() => {
  app.listen(3000, () => console.log('✅ API: http://localhost:3000'));
}).catch(e => console.error('DB Error:', e));
