import { DataTypes } from 'sequelize';
export default (seq) => seq.define('Supplier', {
  name: { type: DataTypes.STRING, allowNull: false },
  contact: DataTypes.STRING,
  phone: DataTypes.STRING
});
