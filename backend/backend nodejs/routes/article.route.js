const express = require('express');
const router = express.Router();
const { Article, Scategorie, Categorie } = require('../models');
const { Op } = require('sequelize');

// Get all articles
router.get('/', async (req, res) => {
  try {
    const articles = await Article.findAll({
      include: [{ 
        model: Scategorie, 
        as: 'scategorie',
        include: [{ model: Categorie, as: 'categorie', attributes: ['id', 'nomcategorie'] }]
      }],
      order: [['id', 'DESC']],
    });
    
    // Map articles to include categorieId from the nested categorie
    const mappedArticles = articles.map(article => {
      const plainArticle = article.toJSON();
      if (article.scategorie && article.scategorie.categorie) {
        plainArticle.categorieId = article.scategorie.categorie.id;
      }
      return plainArticle;
    });
    
    res.status(200).json(mappedArticles);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create article
router.post('/', async (req, res) => {
  try {
    const article = await Article.create(req.body);
    res.status(201).json(article);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get article by ID
router.get('/:articleId', async (req, res) => {
  try {
    const article = await Article.findByPk(req.params.articleId, {
      include: [{ 
        model: Scategorie, 
        as: 'scategorie',
        include: [{ model: Categorie, as: 'categorie', attributes: ['id', 'nomcategorie'] }]
      }],
    });
    if (!article) {
      return res.status(404).json({ message: 'Article not found' });
    }
    
    const plainArticle = article.toJSON();
    if (article.scategorie && article.scategorie.categorie) {
      plainArticle.categorieId = article.scategorie.categorie.id;
    }
    
    res.status(200).json(plainArticle);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update article
router.put('/:articleId', async (req, res) => {
  try {
    const article = await Article.findByPk(req.params.articleId);
    if (!article) {
      return res.status(404).json({ message: 'Article not found' });
    }
    await article.update(req.body);
    const updated = await Article.findByPk(article.id, {
      include: [{ 
        model: Scategorie, 
        as: 'scategorie',
        include: [{ model: Categorie, as: 'categorie', attributes: ['id', 'nomcategorie'] }]
      }],
    });
    
    const plainArticle = updated.toJSON();
    if (updated.scategorie && updated.scategorie.categorie) {
      plainArticle.categorieId = updated.scategorie.categorie.id;
    }
    
    res.status(200).json(plainArticle);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete article
router.delete('/:articleId', async (req, res) => {
  try {
    const article = await Article.findByPk(req.params.articleId);
    if (!article) {
      return res.status(404).json({ message: 'Article not found' });
    }
    await article.destroy();
    res.status(200).json({ message: 'Article deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get articles by subcategory
router.get('/scat/:scategorieId', async (req, res) => {
  try {
    const articles = await Article.findAll({
      where: { scategorieId: req.params.scategorieId },
    });
    res.status(200).json(articles);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get articles by category
router.get('/cat/:categorieId', async (req, res) => {
  try {
    const articles = await Article.findAll({
      include: [{
        model: Scategorie,
        as: 'scategorie',
        where: { categorieId: req.params.categorieId },
      }],
    });
    res.status(200).json(articles);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update quantity only
router.put('/qty/:id', async (req, res) => {
  try {
    const { quantity } = req.body;
    const article = await Article.findByPk(req.params.id);
    if (!article) {
      return res.status(404).json({ message: 'Article not found' });
    }
    article.qtestock = article.qtestock - quantity;
    await article.save();
    res.status(200).json(article);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
