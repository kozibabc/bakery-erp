import express from 'express';
import jwt from 'jsonwebtoken';
import db from '../db.js';

const router = express.Router();
const User = db.models.User;

router.post('/login', async (req, res) => {
  try {
    const { login, password } = req.body;

    // ищем пользователя по логину
    const user = await User.findOne({ where: { login } });
    if (!user) {
      return res.status(401).json({ msg: 'Invalid credentials' });
    }

    // проверяем пароль через метод модели
    const valid = await user.validatePassword(password);
    if (!valid) {
      return res.status(401).json({ msg: 'Invalid credentials' });
    }

    // генерируем токен
    const token = jwt.sign(
      {
        id: user.id,
        login: user.login,
        language: user.language,
        isAdmin: user.isAdmin,
      },
      process.env.JWT_SECRET,
      { expiresIn: '8h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        login: user.login,
        name: user.name,
        language: user.language,
        isAdmin: user.isAdmin,
      },
    });
  } catch (e) {
    console.error('Login error:', e);
    res.status(500).json({ msg: 'Server error' });
  }
});

export default router;
