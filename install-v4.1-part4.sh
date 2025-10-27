#!/bin/bash

###############################################################################
# 🍰 Bakery ERP v4.1 FULL - Part 4/10
# Backend: Models Part 2 (Recipes, Products, Orders, Production, Settings)
###############################################################################

set -e

echo "🍰 Bakery ERP v4.1 FULL - Part 4/10"
echo "==================================="
echo "Backend Models Part 2"
echo ""

###############################################################################
# MODELS - RECIPE
###############################################################################

cat > backend/src/models/Recipe.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Recipe', {
    name: { type: DataTypes.STRING, allowNull: false },
    outputWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 1 },
    outputUnit: { type: DataTypes.STRING, defaultValue: 'кг' },
    lossPercent: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0 }
  });
};
EOF

###############################################################################
# MODELS - RECIPE ITEM
###############################################################################

cat > backend/src/models/RecipeItem.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('RecipeItem', {
    recipeId: DataTypes.INTEGER,
    componentId: DataTypes.INTEGER,
    weight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
    unit: { type: DataTypes.STRING, defaultValue: 'кг' },
    stage: { type: DataTypes.INTEGER, defaultValue: 1 }
  });
};
EOF

###############################################################################
# MODELS - PRODUCT
###############################################################################

cat > backend/src/models/Product.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Product', {
    name: { type: DataTypes.STRING, allowNull: false },
    code: DataTypes.STRING,
    recipeId: DataTypes.INTEGER,
    boxGrossWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
    boxNetWeight: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
    unitsPerBox: { type: DataTypes.INTEGER, defaultValue: 1 },
    basePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    retail1Price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    retail2Price: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
  });
};
EOF

###############################################################################
# MODELS - ORDER
###############################################################################

cat > backend/src/models/Order.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Order', {
    orderNumber: { type: DataTypes.STRING, unique: true },
    clientId: DataTypes.INTEGER,
    status: { 
      type: DataTypes.ENUM('draft', 'confirmed', 'in_production', 'done', 'cancelled'), 
      defaultValue: 'draft' 
    },
    totalBoxes: { type: DataTypes.INTEGER, defaultValue: 0 },
    totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    costOfGoods: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    profit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    notes: DataTypes.TEXT
  });
};
EOF

###############################################################################
# MODELS - ORDER ITEM
###############################################################################

cat > backend/src/models/OrderItem.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('OrderItem', {
    orderId: DataTypes.INTEGER,
    productId: DataTypes.INTEGER,
    boxes: { type: DataTypes.INTEGER, defaultValue: 1 },
    unitPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    totalPrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
  });
};
EOF

###############################################################################
# MODELS - PRODUCTION USAGE
###############################################################################

cat > backend/src/models/ProductionUsage.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('ProductionUsage', {
    orderId: DataTypes.INTEGER,
    componentId: DataTypes.INTEGER,
    qtyUsed: { type: DataTypes.DECIMAL(10, 3), defaultValue: 0 },
    unit: DataTypes.STRING,
    costPerUnit: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    totalCost: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }
  });
};
EOF

###############################################################################
# MODELS - SETTINGS
###############################################################################

cat > backend/src/models/Settings.js << 'EOF'
import { DataTypes } from 'sequelize';

export default (sequelize) => {
  return sequelize.define('Settings', {
    wholesaleMarkup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 10 },
    retail1Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 40 },
    retail2Markup: { type: DataTypes.DECIMAL(5, 2), defaultValue: 70 },
    companyName: { type: DataTypes.STRING, defaultValue: 'Sazhenko Bakery' },
    companyLogo: DataTypes.TEXT,
    priceListFooter: { type: DataTypes.TEXT, defaultValue: 'Ціни дійсні на момент формування' }
  });
};
EOF

echo "✅ Part 4/10 завершена"
echo ""
echo "Создано:"
echo "  ✅ Recipe model"
echo "  ✅ RecipeItem model"
echo "  ✅ Product model"
echo "  ✅ Order model"
echo "  ✅ OrderItem model"
echo "  ✅ ProductionUsage model"
echo "  ✅ Settings model"
echo ""
echo "▶️  Запустите: ./install-v4.1-part5.sh"
echo ""
