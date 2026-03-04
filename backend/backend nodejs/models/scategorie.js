const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Scategorie = sequelize.define('Scategorie', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  nomscategorie: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  imagescat: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  categorieId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'categories',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
}, {
  tableName: 'scategories',
  timestamps: true,
});

module.exports = Scategorie;
