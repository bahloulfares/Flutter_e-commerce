const User = require('./user');
const Categorie = require('./categorie');
const Scategorie = require('./scategorie');
const Article = require('./article');
const Order = require('./order');
const LineOrder = require('./LineOrder');

// Define associations
Categorie.hasMany(Scategorie, {
  foreignKey: 'categorieId',
  as: 'subcategories',
  onDelete: 'CASCADE',
});

Scategorie.belongsTo(Categorie, {
  foreignKey: 'categorieId',
  as: 'categorie',
});

Scategorie.hasMany(Article, {
  foreignKey: 'scategorieId',
  as: 'articles',
  onDelete: 'CASCADE',
});

Article.belongsTo(Scategorie, {
  foreignKey: 'scategorieId',
  as: 'scategorie',
});

Order.hasMany(LineOrder, {
  foreignKey: 'orderId',
  as: 'lineOrder',
  onDelete: 'CASCADE',
});

LineOrder.belongsTo(Order, {
  foreignKey: 'orderId',
  as: 'order',
});

LineOrder.belongsTo(Article, {
  foreignKey: 'articleId',
  as: 'article',
});

Article.hasMany(LineOrder, {
  foreignKey: 'articleId',
  as: 'orders',
});

module.exports = {
  User,
  Categorie,
  Scategorie,
  Article,
  Order,
  LineOrder,
};
