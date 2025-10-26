import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const User = db.models.User;

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

router.get('/', auth, async (_, res) => {
  res.json(await User.findAll({ attributes: { exclude: ['password'] } }));
});

router.post('/', auth, async (req, res) => {
  try {
    const { login, password, name, language } = req.body;
    const user = await User.create({ login, password, name, language });
    res.json({ id: user.id, login, name });
  } catch (e) {
    res.status(400).json({ msg: 'Error' });
  }
});

export default router;
