import { DataTypes } from 'sequelize';
export default (seq) => seq.define('Product', {
  name: { type: DataTypes.STRING, allowNull: false },
  code: { type: DataTypes.STRING, unique: true },
  description: DataTypes.STRING,
  netWeight: DataTypes.DECIMAL,
  unitsPerBox: DataTypes.INTEGER
});
