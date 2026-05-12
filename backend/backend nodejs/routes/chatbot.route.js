const express = require('express');
const router = express.Router();
const { Article, Scategorie, Categorie } = require('../models');

// ── Intent Detection & Response Logic ──────────────────────────────────────

// Detect user intent from message
function detectIntent(message) {
  const msg = message.toLowerCase();
  
  // Define intent patterns
  const patterns = {
    greeting: /\b(bonjour|salut|coucou|hello|hi|bonsoir)\b/i,
    productSearch: /\b(cherche|recherche|trouver|veux|voudrais|besoin|montrez?|voir|afficher|montre)\b/i,
    priceInquiry: /\b(combien|prix|coûte|coute|tarif|cher|pas\s+cher|moins\s+cher)\b/i,
    availabilityCheck: /\b(disponible|en\s+stock|rupture|reste)\b/i,
    categoryBrowse: /\b(catégorie|categorie|rayon|section)\b/i,
    recommendation: /\b(promotion|promo|réduction|reduction|solde|offre|rabais)\b/i,
    orderStatus: /\b(commande|colis|livraison|suivi|suivre|tracking)\b/i,
    help: /\b(aide|help|comment|besoin|question)\b/i,
    goodbye: /\b(au\s+revoir|bye|adieu|à\s+bientôt|a\s+bientot)\b/i,
  };
  
  // Check each pattern
  for (const [intent, pattern] of Object.entries(patterns)) {
    if (pattern.test(msg)) {
      return intent;
    }
  }
  
  return 'unknown';
}

// Extract brand or category from message
function extractSearchTerm(message) {
  const msg = message.toLowerCase();
  
  // Brand patterns
  const brands = ['samsung', 'apple', 'iphone', 'huawei', 'xiaomi', 'sony', 'lg', 'nokia'];
  for (const brand of brands) {
    if (msg.includes(brand)) return brand;
  }
  
  // Category patterns
  const categories = ['smartphone', 'ordinateur', 'vêtement', 'vetement', 'sport', 'casque', 'tablet'];
  for (const cat of categories) {
    if (msg.includes(cat)) return cat;
  }
  
  return null;
}

// Filter products by brand or category
async function filterProducts(searchTerm = null, limit = 5) {
  try {
    let query = {};
    
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      query = {
        [require('sequelize').Op.or]: [
          { designation: { [require('sequelize').Op.like]: `%${term}%` } },
          { marque: { [require('sequelize').Op.like]: `%${term}%` } },
        ]
      };
    }
    
    const articles = await Article.findAll({
      where: query,
      include: [{ 
        model: Scategorie, 
        as: 'scategorie',
        include: [{ model: Categorie, as: 'categorie', attributes: ['id', 'nomcategorie'] }]
      }],
      limit: limit,
      order: [['id', 'DESC']],
    });
    
    return articles.map(article => {
      const plainArticle = article.toJSON();
      if (article.scategorie && article.scategorie.categorie) {
        plainArticle.categorieId = article.scategorie.categorie.id;
      }
      return plainArticle;
    });
  } catch (error) {
    console.error('Error filtering products:', error);
    return [];
  }
}

// ── Main Endpoint ────────────────────────────────────────────────────────────

// POST /api/chatbot/process
// Process user message and return structured response with optional actions
router.post('/process', async (req, res) => {
  try {
    const { userMessage } = req.body;
    
    if (!userMessage) {
      return res.status(400).json({ message: 'userMessage is required' });
    }
    
    // Detect intent
    const intent = detectIntent(userMessage);
    
    // Extract search term (brand/category)
    const searchTerm = extractSearchTerm(userMessage);
    
    // Build response based on intent
    let response = {
      intent,
      message: '',
      action: null,
      products: [],
    };
    
    switch (intent) {
      case 'greeting':
        response.message = '👋 Bienvenue ! Comment puis-je vous aider aujourd\'hui ?';
        break;
        
      case 'productSearch':
        let products = [];
        let message = '';
        
        if (searchTerm) {
          products = await filterProducts(searchTerm, 5);
          message = `✅ Voici les produits correspondant à "${searchTerm}":`;
        } else {
          products = await filterProducts(null, 5);
          message = '✅ Voici nos produits disponibles:';
        }
        
        response.products = products;
        response.message = message;
        
        // Add action to navigate to products page
        response.action = {
          type: 'filter',
          target: '/Products',
          params: searchTerm ? { search: searchTerm } : {},
          message: '📦 Affichage des produits...'
        };
        break;
        
      case 'priceInquiry':
        products = await filterProducts(searchTerm, 4);
        response.products = products;
        response.message = '💰 Nos prix sont très compétitifs ! Voici ce que nous avons en stock:';
        break;
        
      case 'availabilityCheck':
        products = await filterProducts(searchTerm, 5);
        response.products = products;
        response.message = products.length > 0 
          ? '📊 Voici les articles actuellement en stock:'
          : '❌ Désolé, aucun article disponible pour cette recherche.';
        break;
        
      case 'categoryBrowse':
        products = await filterProducts(null, 6);
        response.products = products;
        response.message = '📂 Parcourez nos catégories:';
        response.action = {
          type: 'redirect',
          target: '/Products',
          message: 'Naviguer vers les produits...'
        };
        break;
        
      case 'recommendation':
        products = await filterProducts(null, 4);
        response.products = products;
        response.message = '🎁 Découvrez nos meilleures offres et promotions:';
        break;
        
      case 'orderStatus':
        response.message = '📋 Pour suivre votre commande, veuillez nous contacter ou consulter votre email de confirmation.';
        break;
        
      case 'help':
        response.message = '❓ Je peux vous aider avec:\n• Rechercher des produits\n• Vérifier les prix\n• Consulter la disponibilité\n• Voir les promotions\n• Suivre une commande';
        response.action = {
          type: 'message',
          message: 'Menu d\'aide affiché'
        };
        break;
        
      case 'goodbye':
        response.message = '👋 Au revoir ! Merci d\'avoir visité notre boutique. À bientôt !';
        break;
        
      default:
        response.message = '❓ Je n\'ai pas bien compris. Vous cherchez des produits, des prix, ou vous avez besoin d\'aide ?';
    }
    
    res.status(200).json(response);
    
  } catch (error) {
    console.error('Error in chatbot process:', error);
    res.status(500).json({ 
      message: 'Erreur interne du serveur',
      error: error.message 
    });
  }
});

module.exports = router;
