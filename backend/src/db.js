import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';
import User from './models/User.js';
import Product from './models/Product.js';
import Client from './models/Client.js';
import Supplier from './models/Supplier.js';

dotenv.config();

const seq = new Sequelize(
  process.env.DB_NAME || 'bakery_erp',
  process.env.DB_USER || 'bakery_user',
  process.env.DB_PASSWORD || 'bakery_pass_2024',
  {
    host: process.env.DB_HOST || 'db',
    port: 5432,
    dialect: 'postgres',
    logging: false
  }
);

User(seq);
Product(seq);
Client(seq);
Supplier(seq);

export default seq;
