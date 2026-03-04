const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Order = sequelize.define('Order', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  client: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  total: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  status: {
    type: DataTypes.ENUM('Not processed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'),
    defaultValue: 'Not processed',
  },
}, {
  tableName: 'orders',
  timestamps: true,
});

module.exports = Order;