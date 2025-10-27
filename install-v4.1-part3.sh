#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 FULL - Part 3/10
# Backend: Models Part 1 (Users, Permissions, Clients, Suppliers, Components)
###############################################################################

set -e

echo "🍰 Bakery ERP v4.1 FULL - Part 3/10"
echo "==================================="
echo "Backend Models Part 1"
echo ""

###############################################################################
# MODELS - USER
###############################################################################

cat > backend/src/models/User.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('User', {
    login: { type: DataTypes.STRING, unique: true, allowNull: false },
    password: { type: DataTypes.STRING, allowNull: false },
    name: DataTypes.STRING,
    email: DataTypes.STRING,
    phone: DataTypes.STRING,
    telegram: DataTypes.STRING,
    role: { type: DataTypes.ENUM('admin', 'manager'), defaultValue: 'manager' },
    language: { type: DataTypes.STRING, defaultValue: 'uk' }
  });
};
EOF

###############################################################################
# MODELS - PERMISSION
###############################################################################

cat > backend/src/models/Permission.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Permission', {
    userId: { type: DataTypes.INTEGER, unique: true },
    canViewStock: { type: DataTypes.BOOLEAN, defaultValue: false },
    canEditStock: { type: DataTypes.BOOLEAN, defaultValue: false },
    canAddPurchases: { type: DataTypes.BOOLEAN, defaultValue: false },
    canStartProduction: { type: DataTypes.BOOLEAN, defaultValue: false },
    canViewFinances: { type: DataTypes.BOOLEAN, defaultValue: false },
    canEditSettings: { type: DataTypes.BOOLEAN, defaultValue: false },
    canManageUsers: { type: DataTypes.BOOLEAN, defaultValue: false },
    canViewOrders: { type: DataTypes.BOOLEAN, defaultValue: true },
    canEditOrders: { type: DataTypes.BOOLEAN, defaultValue: false },
    canViewRecipes: { type: DataTypes.BOOLEAN, defaultValue: true },
    canEditRecipes: { type: DataTypes.BOOLEAN, defaultValue: false }
  });
};
EOF

###############################################################################
# MODELS - CLIENT
###############################################################################

cat > backend/src/models/Client.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Client', {
    name: { type: DataTypes.STRING, allowNull: false },
    phone: DataTypes.STRING,
    email: DataTypes.STRING,
    telegram: DataTypes.STRING,
    type: { 
      type: DataTypes.ENUM('wholesale', 'retail1', 'retail2'), 
      defaultValue: 'wholesale' 
    },
    notes: DataTypes.TEXT
  });
};
EOF

###############################################################################
# MODELS - SUPPLIER
###############################################################################

cat > backend/src/models/Supplier.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Supplier', {
    name: { type: DataTypes.STRING, allowNull: false },
    phone: DataTypes.STRING,
    email: DataTypes.STRING,
    telegram: DataTypes.STRING,
    notes: DataTypes.TEXT
  });
};
EOF

###############################################################################
# MODELS - COMPONENT
###############################################################################

cat > backend/src/models/Component.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Component', {
    name: { type: DataTypes.STRING, allowNull: false },
    type: { 
      type: DataTypes.ENUM('RAW', 'SEMI_INTERNAL', 'SEMI_EXTERNAL', 'PACK'), 
      defaultValue: 'RAW' 
    },
    unit: { type: DataTypes.STRING, defaultValue: 'кг' },
    currentPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    supplierId: DataTypes.INTEGER
  });
};
EOF

###############################################################################
# MODELS - STOCK
###############################################################################

cat > backend/src/models/Stock.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Stock', {
    componentId: { type: DataTypes.INTEGER, unique: true },
    qtyOnHand: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
    avgCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
  });
};
EOF

###############################################################################
# MODELS - PURCHASE
###############################################################################

cat > backend/src/models/Purchase.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Purchase', {
    date: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
    supplierId: DataTypes.INTEGER,
    componentId: DataTypes.INTEGER,
    qty: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
    unit: DataTypes.STRING,
    pricePerUnit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    totalSum: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    transportCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    notes: DataTypes.TEXT
  });
};
EOF

###############################################################################
# MODELS - PRICE HISTORY
###############################################################################

cat > backend/src/models/PriceHistory.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('PriceHistory', {
    componentId: DataTypes.INTEGER,
    date: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
    price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    source: { type: DataTypes.STRING, defaultValue: 'manual' }
  });
};
EOF

echo "✅ Part 3/10 завершена"
echo ""
echo "Создано:"
echo "  ✅ User model"
echo "  ✅ Permission model"
echo "  ✅ Client model"
echo "  ✅ Supplier model"
echo "  ✅ Component model"
echo "  ✅ Stock model"
echo "  ✅ Purchase model"
echo "  ✅ PriceHistory model"
echo ""
echo "▶️  Запустите: ./install-v4.1-part4.sh"
echo ""
