const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Article = sequelize.define('Article', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  reference: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
  },
  designation: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
  },
  prix: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  marque: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  qtestock: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  imageart: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  scategorieId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'scategories',
      key: 'id',
    },
    onDelete: 'CASCADE',
  },
}, {
  tableName: 'articles',
  timestamps: true,
});

module.exports = Article;
