const express = require('express');
const router = express.Router();
const { Scategorie, Categorie } = require('../models');

// Get all subcategories
router.get('/', async (req, res) => {
  try {
    const scategories = await Scategorie.findAll({
      include: [{ model: Categorie, as: 'categorie' }],
      order: [['id', 'DESC']],
    });
    res.status(200).json(scategories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create subcategory
router.post('/', async (req, res) => {
  try {
    const { nomscategorie, imagescat, categorieId } = req.body;
    const scategorie = await Scategorie.create({
      nomscategorie,
      imagescat,
      categorieId,
    });
    res.status(201).json(scategorie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get subcategory by ID
router.get('/:scategorieId', async (req, res) => {
  try {
    const scategorie = await Scategorie.findByPk(req.params.scategorieId);
    if (!scategorie) {
      return res.status(404).json({ message: 'Subcategory not found' });
    }
    res.status(200).json(scategorie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update subcategory
router.put('/:scategorieId', async (req, res) => {
  try {
    const scategorie = await Scategorie.findByPk(req.params.scategorieId);
    if (!scategorie) {
      return res.status(404).json({ message: 'Subcategory not found' });
    }
    await scategorie.update(req.body);
    res.status(200).json(scategorie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete subcategory
router.delete('/:scategorieId', async (req, res) => {
  try {
    const scategorie = await Scategorie.findByPk(req.params.scategorieId);
    if (!scategorie) {
      return res.status(404).json({ message: 'Subcategory not found' });
    }
    await scategorie.destroy();
    res.status(200).json({ message: 'Subcategory deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get subcategories by category
router.get('/cat/:categorieId', async (req, res) => {
  try {
    const scategories = await Scategorie.findAll({
      where: { categorieId: req.params.categorieId },
    });
    res.status(200).json(scategories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
