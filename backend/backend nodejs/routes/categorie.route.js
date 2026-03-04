const express = require('express');
const router = express.Router();
const { Categorie } = require('../models');

// Get all categories
router.get('/', async (req, res) => {
  try {
    const categories = await Categorie.findAll({
      order: [['id', 'DESC']],
    });
    res.status(200).json(categories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create category
router.post('/', async (req, res) => {
  try {
    const { nomcategorie, imagecategorie } = req.body;
    const categorie = await Categorie.create({
      nomcategorie,
      imagecategorie,
    });
    res.status(201).json(categorie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get category by ID
router.get('/:categorieId', async (req, res) => {
  try {
    const categorie = await Categorie.findByPk(req.params.categorieId);
    if (!categorie) {
      return res.status(404).json({ message: 'Category not found' });
    }
    res.status(200).json(categorie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update category
router.put('/:categorieId', async (req, res) => {
  try {
    const categorie = await Categorie.findByPk(req.params.categorieId);
    if (!categorie) {
      return res.status(404).json({ message: 'Category not found' });
    }
    await categorie.update(req.body);
    res.status(200).json(categorie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete category
router.delete('/:categorieId', async (req, res) => {
  try {
    const categorie = await Categorie.findByPk(req.params.categorieId);
    if (!categorie) {
      return res.status(404).json({ message: 'Category not found' });
    }
    await categorie.destroy();
    res.status(200).json({ message: 'Category deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;