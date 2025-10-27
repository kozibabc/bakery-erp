#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 FULL - Part 2/10
# Backend: Dockerfile, package.json, database config
###############################################################################

set -e

echo "🍰 Bakery ERP v4.1 FULL - Part 2/10"
echo "==================================="
echo "Backend Base Setup"
echo ""

###############################################################################
# BACKEND DOCKERFILE
###############################################################################

cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

###############################################################################
# BACKEND PACKAGE.JSON
###############################################################################

cat > backend/package.json << 'EOF'
{
  "name": "bakery-backend",
  "version": "4.1.0",
  "type": "module",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "sequelize": "^6.35.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "pdfkit": "^0.13.0",
    "exceljs": "^4.3.0",
    "multer": "^1.4.5-lts.1",
    "dotenv": "^16.3.1"
  }
}
EOF

###############################################################################
# DATABASE CONFIG
###############################################################################

cat > backend/src/database.js << 'EOF'
import { Sequelize } from 'sequelize';

const sequelize = new Sequelize(process.env.DATABASE_URL || 'postgresql://bakery:bakery123@localhost:5432/bakery_erp', {
  logging: false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000
  },
  dialect: 'postgres'
});

export default sequelize;
EOF

###############################################################################
# HELPERS
###############################################################################

cat > backend/src/services/helpers.js << 'EOF'
export const sanitizeNumeric = (value) => {
  if (value === '' || value === null || value === undefined) return 0;
  const num = parseFloat(value);
  return isNaN(num) ? 0 : num;
};

export const generateOrderNumber = () => {
  return `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
};

export const formatTelegramLink = (username) => {
  if (!username) return null;
  const clean = username.replace('@', '');
  return `https://t.me/${clean}`;
};
EOF

###############################################################################
# AUTH MIDDLEWARE
###############################################################################

cat > backend/src/middleware/auth.js << 'EOF'
import jwt from 'jsonwebtoken';

export const authenticate = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'my-secret-key-2024');
    req.userId = decoded.id;
    req.userRole = decoded.role;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

export const requireAdmin = (req, res, next) => {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};
EOF

echo "✅ Part 2/10 завершена"
echo ""
echo "Создано:"
echo "  ✅ backend/Dockerfile"
echo "  ✅ backend/package.json"
echo "  ✅ backend/src/database.js"
echo "  ✅ backend/src/services/helpers.js"
echo "  ✅ backend/src/middleware/auth.js"
echo ""
echo "▶️  Запустите: ./install-v4.1-part3.sh"
echo ""
