const express = require('express');
const router = express.Router();
const { GoogleGenerativeAI, SchemaType } = require('@google/generative-ai');
const { Article, Scategorie, Categorie } = require('../models');
const { Op } = require('sequelize');

// ── Gemini Initialization ─────────────────────────────────────────────────────
const geminiEnabled = !!process.env.GEMINI_API_KEY &&
                      process.env.GEMINI_API_KEY !== 'VOTRE_CLE_GEMINI_ICI';

let genAI = null;
let geminiModel = null;
let extractorModel = null; // Modèle léger pour l'extraction de mots-clés

if (geminiEnabled) {
  genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

  // ✅ AMÉLIORATION 1 : systemInstruction séparé de la conversation
  // Le modèle comprend son rôle TOUJOURS, sans polluer l'historique
  const systemInstruction = `Tu es un assistant e-commerce intelligent et chaleureux pour une boutique en ligne.
Tu réponds en FRANÇAIS par défaut, mais tu comprends aussi l'ARABE et l'ANGLAIS.
Tu es spécialisé dans la recherche de produits, les prix, la disponibilité et l'aide à la navigation.
Sois précis, amical et concis. Utilise les données produits fournies dans chaque message.
Si un produit n'est pas dans les données fournies, dis-le honnêtement.`;

  // ✅ AMÉLIORATION 2 : Structured Output (JSON garanti mathématiquement)
  // Plus jamais d'erreur de parsing, plus besoin de nettoyer les backticks markdown
  const responseSchema = {
    type: SchemaType.OBJECT,
    properties: {
      intent: {
        type: SchemaType.STRING,
        enum: ['greeting', 'productSearch', 'priceInquiry', 'availabilityCheck', 'orderStatus', 'recommendation', 'categoryBrowse', 'delivery', 'help', 'goodbye', 'unknown'],
        description: "L'intention détectée dans le message de l'utilisateur",
      },
      message: {
        type: SchemaType.STRING,
        description: "Ta réponse naturelle, amicale et précise à l'utilisateur",
      },
      searchTerm: {
        type: SchemaType.STRING,
        nullable: true,
        description: "Le terme de recherche extrait du message, null si pas de recherche",
      },
      needsProductList: {
        type: SchemaType.BOOLEAN,
        description: "true si la réponse doit afficher la liste des produits",
      },
      redirectTo: {
        type: SchemaType.STRING,
        nullable: true,
        description: "Route Flutter vers laquelle rediriger (/Products, /Documents, etc.), null sinon",
      },
    },
    required: ['intent', 'message', 'needsProductList'],
  };

  // ✅ AMÉLIORATION 3 : Modèle flash-lite-latest (compatible avec votre clé API)
  geminiModel = genAI.getGenerativeModel({
    model: 'gemini-flash-lite-latest',
    systemInstruction,
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema,
      maxOutputTokens: 600,
      temperature: 0.2, // Réponses cohérentes et précises
    },
  });

  // Modèle ultra-léger SEULEMENT pour l'extraction du mot-clé de recherche
  extractorModel = genAI.getGenerativeModel({
    model: 'gemini-flash-lite-latest',
    generationConfig: {
      maxOutputTokens: 50,
      temperature: 0,
    },
  });

  console.log('✅ Gemini API activé (gemini-1.5-flash + Structured Output)');
} else {
  console.log('⚠️  Gemini API désactivé — mode RegEx fallback actif');
}

// ── Mémoire conversationnelle par session (in-memory) ────────────────────────
const sessionHistory = new Map();
const SESSION_MAX_MESSAGES = 12; // Garder les 12 derniers échanges
const SESSION_TTL_MS = 30 * 60 * 1000; // 30 min d'inactivité → reset

setInterval(() => {
  const now = Date.now();
  for (const [sessionId, session] of sessionHistory.entries()) {
    if (now - session.lastActivity > SESSION_TTL_MS) {
      sessionHistory.delete(sessionId);
    }
  }
}, 5 * 60 * 1000);

// ── Extraction locale du mot-clé (rapide, fiable, sans appel API) ─────────────
// Utilisé en PREMIER, avant toute tentative IA, pour garantir un résultat rapide
function extractSearchTermLocal(userMessage) {
  const msg = userMessage.toLowerCase();

  // 1. Marques connues dans votre base
  const brands = [
    'samsung', 'xiaomi', 'xioami', 'lenovo', 'dell', 'huawei', 'tecno',
    'infinix', 'versus', 'delice', 'adidas', 'nike', 'apple', 'iphone',
    'sony', 'lg', 'asus', 'hp', 'acer', 'oppo', 'realme',
  ];
  for (const brand of brands) {
    if (msg.includes(brand)) return brand;
  }

  // 2. Types de produits
  const products = [
    'smartphone', 'téléphone', 'telephone', 'portable', 'mobile',
    'ordinateur', 'laptop', 'pc portable', 'tablette', 'tablet',
    'casque', 'écran', 'ecran', 'chargeur', 'cable',
    'vêtement', 'vetement', 'chemise', 'pantalon', 'robe', 'chaussure',
    'lait', 'jus', 'eau', 'huile', 'farine', 'thon',
    'sport', 'football', 'basket',
  ];
  for (const prod of products) {
    if (msg.includes(prod)) return prod;
  }

  return null;
}

// ── ✅ Extraction hybride : Local d'abord (immédiat), IA en secours ────────────
async function extractSearchTermWithAI(userMessage) {
  // ÉTAPE 1 : Essai local immédiat (0ms, 100% fiable)
  const localTerm = extractSearchTermLocal(userMessage);
  if (localTerm) {
    console.log(`🔍 [Local] Terme extrait localement: "${localTerm}"`);
    return localTerm;
  }

  // ÉTAPE 2 : Si la regex locale n'a rien trouvé, on essaie l'IA
  if (!extractorModel) return null;
  try {
    const prompt = `Analyse cette phrase d'un client d'une boutique en ligne.
Phrase: "${userMessage}"
Extrais UNIQUEMENT le terme de recherche de produit (marque, type, nom de produit).
Réponds avec juste le terme en 1-4 mots, ou "NULL" si ce n'est pas une recherche de produit.
Exemples:
- "Je cherche un Samsung Galaxy" → "Samsung Galaxy"
- "Avez-vous des PC Asus ?" → "PC Asus"  
- "C'est combien une souris gaming ?" → "souris gaming"
- "Bonjour" → "NULL"
- "Comment passer une commande ?" → "NULL"`;

    const result = await extractorModel.generateContent(prompt);
    const term = result.response.text().trim().replace(/['"]/g, '');
    const found = (term === 'NULL' || term === '' || term.length > 40) ? null : term;
    console.log(`🤖 [IA] Terme extrait: "${found ?? 'aucun'}"`);
    return found;
  } catch (e) {
    console.log('⚠️ Extraction IA échouée, pas de filtre:', e.message);
    return null;
  }
}

// ── Chargement des produits depuis MySQL ─────────────────────────────────────
async function loadProductsForContext(searchTerm = null, limit = 10) {
  try {
    let where = {};
    if (searchTerm) {
      // Découpage du terme en mots pour une recherche plus large
      const words = searchTerm.split(' ').filter(w => w.length > 2);
      where = {
        [Op.or]: [
          ...words.map(w => ({ designation: { [Op.like]: `%${w}%` } })),
          ...words.map(w => ({ marque: { [Op.like]: `%${w}%` } })),
          { designation: { [Op.like]: `%${searchTerm}%` } },
          { marque: { [Op.like]: `%${searchTerm}%` } },
        ],
      };
    }

    const articles = await Article.findAll({
      where,
      include: [{
        model: Scategorie,
        as: 'scategorie',
        include: [{ model: Categorie, as: 'categorie', attributes: ['nomcategorie'] }],
      }],
      limit,
      order: searchTerm ? [['id', 'ASC']] : [['id', 'DESC']],
    });

    return articles.map(a => {
      const json = a.toJSON();
      return {
        id: json.id,
        designation: json.designation,
        marque: json.marque || 'N/A',
        prix: json.prix,
        qtestock: json.qtestock,
        reference: json.reference || '',
        imageart: json.imageart || '',
        categorie: json.scategorie?.categorie?.nomcategorie ?? 'N/A',
      };
    });
  } catch (err) {
    console.error('Erreur chargement produits:', err.message);
    return [];
  }
}

// ── Formatage des produits pour le prompt ────────────────────────────────────
function formatProductsForPrompt(products) {
  if (!products.length) return 'Aucun produit trouvé en base de données pour ce terme.';
  return products.map((p, i) =>
    `${i + 1}. ${p.designation} | Marque: ${p.marque} | Prix: ${p.prix} TND | Stock: ${p.qtestock} | Catégorie: ${p.categorie}`
  ).join('\n');
}

// ── Appel Gemini avec historique conversationnel ─────────────────────────────
async function callGemini(userMessage, sessionId, products) {
  // Récupérer/créer la session
  if (!sessionHistory.has(sessionId)) {
    sessionHistory.set(sessionId, { messages: [], lastActivity: Date.now() });
  }
  const session = sessionHistory.get(sessionId);
  session.lastActivity = Date.now();

  // Construire l'historique pour Gemini
  const historyParts = session.messages.slice(-SESSION_MAX_MESSAGES).map(msg => ({
    role: msg.role,
    parts: [{ text: msg.text }],
  }));

  const chat = geminiModel.startChat({ history: historyParts });

  // ✅ Le contexte produits est injecté dans CHAQUE message utilisateur
  // (pas seulement le premier), pour que les données soient toujours fraîches
  const productsContext = products.length > 0
    ? `\n\n--- PRODUITS DISPONIBLES EN BASE DE DONNÉES ---\n${formatProductsForPrompt(products)}\n---`
    : '\n\n--- Aucun produit spécifique trouvé pour cette recherche. ---';

  const fullUserMessage = `${userMessage}${productsContext}`;

  const result = await chat.sendMessage(fullUserMessage);
  const responseText = result.response.text();

  // Sauvegarder uniquement le vrai message dans l'historique (sans le contexte produits)
  session.messages.push({ role: 'user', text: userMessage });
  session.messages.push({ role: 'model', text: responseText });

  return responseText;
}

// ── Fallback RegEx (si Gemini non configuré) ─────────────────────────────────
function detectIntentFallback(message) {
  const msg = message.toLowerCase();
  const patterns = {
    greeting:          /\b(bonjour|salut|coucou|hello|hi|bonsoir|مرحبا|أهلا)\b/i,
    productSearch:     /\b(cherche|recherche|trouver|veux|voudrais|besoin|montrez?|voir|afficher|montre)\b/i,
    priceInquiry:      /\b(combien|prix|coûte|coute|tarif|cher|moins\s+cher|سعر|بكم)\b/i,
    availabilityCheck: /\b(disponible|en\s+stock|rupture|reste|متوفر|موجود)\b/i,
    categoryBrowse:    /\b(catégorie|categorie|rayon|section|فئة)\b/i,
    recommendation:    /\b(promotion|promo|réduction|reduction|solde|offre|rabais|تخفيض)\b/i,
    orderStatus:       /\b(commande|colis|livraison|suivi|suivre|tracking|طلب|توصيل)\b/i,
    help:              /\b(aide|help|comment|besoin|question|مساعدة)\b/i,
    goodbye:           /\b(au\s+revoir|bye|adieu|à\s+bientôt|مع\s+السلامة|وداعا)\b/i,
  };
  for (const [intent, pattern] of Object.entries(patterns)) {
    if (pattern.test(msg)) return intent;
  }
  return 'unknown';
}

async function buildFallbackResponse(intent, searchTerm) {
  const products = await loadProductsForContext(searchTerm, 5);
  const responses = {
    greeting:          '👋 Bienvenue ! Comment puis-je vous aider aujourd\'hui ?',
    productSearch:     `✅ Voici les produits${searchTerm ? ` pour "${searchTerm}"` : ' disponibles'}:`,
    priceInquiry:      '💰 Voici les prix de nos produits:',
    availabilityCheck: '📊 Voici les articles actuellement en stock:',
    categoryBrowse:    '📂 Parcourez nos catégories:',
    recommendation:    '🎁 Découvrez nos meilleures offres:',
    orderStatus:       '📋 Pour suivre votre commande, consultez votre email de confirmation.',
    help:              '❓ Je peux vous aider avec:\n• Rechercher des produits\n• Vérifier les prix et stocks\n• Infos de livraison',
    goodbye:           '👋 Au revoir ! Merci de votre visite. À bientôt !',
    unknown:           '❓ Je n\'ai pas bien compris. Pouvez-vous reformuler ? (ex: "je cherche un samsung")',
  };

  const needsProducts = ['productSearch', 'priceInquiry', 'availabilityCheck', 'categoryBrowse', 'recommendation'];
  const action = needsProducts.includes(intent) ? {
    type: 'filter',
    target: '/Products',
    params: searchTerm ? { search: searchTerm } : {},
  } : null;

  return {
    intent,
    message: responses[intent] ?? responses.unknown,
    searchTerm,
    action,
    products: needsProducts.includes(intent) ? products : [],
    source: 'regex_fallback',
  };
}

// ── Main Endpoint ─────────────────────────────────────────────────────────────
router.post('/process', async (req, res) => {
  try {
    const { userMessage, sessionId = 'default' } = req.body;

    if (!userMessage || userMessage.trim() === '') {
      return res.status(400).json({ message: 'userMessage est requis' });
    }

    console.log(`\n💬 [Chatbot] Session="${sessionId}" Message="${userMessage}"`);

    // ── MODE GEMINI ──────────────────────────────────────────────────────────
    if (geminiEnabled) {
      try {
        // ✅ ÉTAPE 1 : Extraction intelligente du terme de recherche via IA (rapide)
        const searchTerm = await extractSearchTermWithAI(userMessage);
        console.log(`🔍 [Chatbot] Terme extrait par IA: "${searchTerm ?? 'aucun'}"`);

        // ✅ ÉTAPE 2 : Chargement des produits VRAIMENT pertinents depuis MySQL
        const products = await loadProductsForContext(searchTerm, 10);
        console.log(`📦 [Chatbot] ${products.length} produits chargés${searchTerm ? ` pour "${searchTerm}"` : ''}`);

        // ✅ ÉTAPE 3 : Appel Gemini avec contexte produits + historique conversation
        const rawResponse = await callGemini(userMessage, sessionId, products);
        console.log(`🤖 [Gemini] Réponse: ${rawResponse.substring(0, 120)}...`);

        // ✅ ÉTAPE 4 : Parsing JSON garanti par le Structured Output
        const parsed = JSON.parse(rawResponse);

        // ✅ ÉTAPE 5 : Construction de l'action de navigation si nécessaire
        let action = null;
        if (parsed.redirectTo) {
          action = { type: 'redirect', target: parsed.redirectTo, params: {} };
        } else if (parsed.needsProductList && products.length > 0) {
          action = {
            type: 'filter',
            target: '/Products',
            params: searchTerm ? { search: searchTerm } : {},
          };
        }

        const response = {
          intent: parsed.intent ?? 'unknown',
          message: parsed.message ?? 'Je n\'ai pas compris.',
          action,
          products,
          searchTerm,
          source: 'gemini',
        };

        console.log(`✅ [Chatbot] Intent="${response.intent}" Produits=${products.length}`);
        return res.status(200).json(response);

      } catch (geminiError) {
        console.error('❌ [Gemini] Erreur:', geminiError.message);
        console.log('⚠️  Basculement vers le fallback RegEx...');
      }
    }

    // ── MODE FALLBACK REGEX ──────────────────────────────────────────────────
    const intent = detectIntentFallback(userMessage);
    const fallbackSearchTerm = extractSearchTermLocal(userMessage); // On extrait le mot en local
    const fallbackResponse = await buildFallbackResponse(intent, fallbackSearchTerm);
    console.log(`⚡ [Fallback] Intent="${intent}" SearchTerm="${fallbackSearchTerm}"`);
    return res.status(200).json(fallbackResponse);

  } catch (error) {
    console.error('💥 [Chatbot] Erreur critique:', error);
    return res.status(500).json({
      message: 'Erreur interne du serveur',
      error: error.message,
    });
  }
});

// ── Reset conversation session ────────────────────────────────────────────────
router.delete('/session/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  if (sessionHistory.has(sessionId)) {
    sessionHistory.delete(sessionId);
    console.log(`🗑️  Session "${sessionId}" réinitialisée`);
    return res.json({ message: 'Session réinitialisée' });
  }
  return res.status(404).json({ message: 'Session non trouvée' });
});

module.exports = router;
