import { DataTypes } from 'sequelize';
import bcrypt from 'bcryptjs';

export default (seq) => {
  const User = seq.define('User', {
    login: { type: DataTypes.STRING, unique: true, allowNull: false },
    password: { type: DataTypes.STRING, allowNull: false },
    name: DataTypes.STRING,
    phone: DataTypes.STRING,
    description: DataTypes.STRING,
    language: { type: DataTypes.ENUM('ru', 'en', 'uk'), defaultValue: 'uk' },
    isAdmin: { type: DataTypes.BOOLEAN, defaultValue: false }
  });

  User.beforeCreate(async u => {
    u.password = await bcrypt.hash(u.password, 10);
  });

  User.prototype.validatePassword = function(pwd) {
    return bcrypt.compare(pwd, this.password);
  };

  return User;
};
