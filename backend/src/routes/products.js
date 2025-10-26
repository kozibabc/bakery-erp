import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const Product = db.models.Product;

function auth(req, res, next) {
  try {
    const token = req.headers?.authorization?.split(' ')[1];
    if (!token) throw new Error();
    jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ msg: 'Not authorized' });
  }
}

router.get('/', auth, async (_, res) => res.json(await Product.findAll()));
router.post('/', auth, async (req, res) => {
  const p = await Product.create(req.body);
  res.json(p);
});

export default router;
