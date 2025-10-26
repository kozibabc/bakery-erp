import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const Client = db.models.Client;

function auth(req, res, next) {
  try {
    jwt.verify(req.headers?.authorization?.split(' ')[1], process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ msg: 'Not authorized' });
  }
}

router.get('/', auth, async (_, res) => res.json(await Client.findAll()));
router.post('/', auth, async (req, res) => res.json(await Client.create(req.body)));

export default router;
