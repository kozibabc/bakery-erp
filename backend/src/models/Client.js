import { DataTypes } from 'sequelize';
export default (seq) => seq.define('Client', {
  name: { type: DataTypes.STRING, allowNull: false },
  contact: DataTypes.STRING,
  phone: DataTypes.STRING,
  priceTier: DataTypes.ENUM('wholesale', 'retail1', 'retail2')
});
