const express = require('express');
const router = express.Router();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { Article, Scategorie, Categorie } = require('../models');
const { Op } = require('sequelize');

// ── Gemini Initialization ─────────────────────────────────────────────────────
// La clé est sécurisée côté serveur, jamais exposée au client Flutter
const geminiEnabled = !!process.env.GEMINI_API_KEY && 
                      process.env.GEMINI_API_KEY !== 'VOTRE_CLE_GEMINI_ICI';

let genAI = null;
let geminiModel = null;

if (geminiEnabled) {
  genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  geminiModel = genAI.getGenerativeModel({ model: 'gemini-flash-lite-latest' });
  console.log('✅ Gemini API activé (gemini-flash-lite-latest)');
} else {
  console.log('⚠️  Gemini API désactivé — mode RegEx fallback actif');
  console.log('   → Ajoutez GEMINI_API_KEY dans .env pour activer l\'IA');
}

// ── Mémoire conversationnelle par session (in-memory) ────────────────────────
// Clé = sessionId (envoyé par Flutter), valeur = historique messages
const sessionHistory = new Map();
const SESSION_MAX_MESSAGES = 10; // Garder les 10 derniers échanges
const SESSION_TTL_MS = 30 * 60 * 1000; // 30 min d'inactivité → reset

// Nettoyage automatique des sessions expirées
setInterval(() => {
  const now = Date.now();
  for (const [sessionId, session] of sessionHistory.entries()) {
    if (now - session.lastActivity > SESSION_TTL_MS) {
      sessionHistory.delete(sessionId);
    }
  }
}, 5 * 60 * 1000); // Vérifier toutes les 5 min

// ── Chargement des produits depuis MySQL ─────────────────────────────────────
async function loadProductsForContext(searchTerm = null, limit = 8) {
  try {
    let where = {};
    if (searchTerm) {
      where = {
        [Op.or]: [
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
      order: [['id', 'DESC']],
    });

    return articles.map(a => {
      const json = a.toJSON();
      return {
        id: json.id,
        designation: json.designation,
        marque: json.marque,
        prix: json.prix,
        qtestock: json.qtestock,
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
  if (!products.length) return 'Aucun produit trouvé en base de données.';
  return products.map((p, i) =>
    `${i + 1}. ${p.designation} | Marque: ${p.marque} | Prix: ${p.prix} DA | Stock: ${p.qtestock} unités | Catégorie: ${p.categorie}`
  ).join('\n');
}

// ── Prompt système Gemini ────────────────────────────────────────────────────
function buildSystemPrompt(products) {
  const productsText = formatProductsForPrompt(products);

  return `Tu es un assistant intelligent pour une boutique e-commerce algérienne.
Tu réponds en FRANÇAIS par défaut, mais tu comprends aussi l'ARABE et l'ANGLAIS.
Tu es capable de comprendre les fautes de frappe et les variations de langue.

## PRODUITS ACTUELLEMENT EN BASE DE DONNÉES (données réelles MySQL):
${productsText}

## TES CAPACITÉS:
- Rechercher des produits par nom, marque, catégorie
- Donner les prix exacts depuis la base de données
- Vérifier le stock disponible
- Guider l'utilisateur dans sa navigation
- Répondre aux questions sur les commandes et la livraison
- Recommander des produits

## FORMAT DE RÉPONSE OBLIGATOIRE (JSON strict, rien d'autre):
{
  "intent": "greeting|productSearch|priceInquiry|availabilityCheck|orderStatus|recommendation|categoryBrowse|delivery|help|goodbye|unknown",
  "message": "Ta réponse naturelle et amicale ici",
  "searchTerm": "terme_recherche_ou_null",
  "action": null ou {"type": "redirect|filter|message", "target": "/Products", "params": {}}
}

## RÈGLES IMPORTANTES:
1. Réponds UNIQUEMENT en JSON valide, sans markdown ni backticks
2. Le champ "message" doit être naturel, chaleureux et utile
3. Si l'utilisateur mentionne un produit spécifique, mets son nom dans "searchTerm"
4. Pour les prix et stocks, utilise EXACTEMENT les données fournies ci-dessus
5. Si une info n'est pas dans les données, dis-le honnêtement`;
}

// ── Appel Gemini avec historique conversationnel ─────────────────────────────
async function callGemini(userMessage, sessionId, products) {
  const systemPrompt = buildSystemPrompt(products);

  // Récupérer/créer la session
  if (!sessionHistory.has(sessionId)) {
    sessionHistory.set(sessionId, { messages: [], lastActivity: Date.now() });
  }
  const session = sessionHistory.get(sessionId);
  session.lastActivity = Date.now();

  // Construire l'historique pour Gemini (format parts[])
  const historyParts = session.messages.slice(-SESSION_MAX_MESSAGES).map(msg => ({
    role: msg.role,
    parts: [{ text: msg.text }],
  }));

  // Créer le chat avec historique
  const chat = geminiModel.startChat({
    history: historyParts,
    generationConfig: {
      maxOutputTokens: 500,
      temperature: 0.3, // Réponses cohérentes (0=déterministe, 1=créatif)
    },
  });

  // Message complet avec contexte produits (uniquement le premier tour ou si contexte change)
  const fullMessage = session.messages.length === 0
    ? `${systemPrompt}\n\nUtilisateur: ${userMessage}`
    : userMessage;

  const result = await chat.sendMessage(fullMessage);
  const responseText = result.response.text().trim();

  // Sauvegarder dans l'historique
  session.messages.push({ role: 'user', text: userMessage });
  session.messages.push({ role: 'model', text: responseText });

  return responseText;
}

// ── Parsing sécurisé du JSON Gemini ─────────────────────────────────────────
function parseGeminiResponse(rawText) {
  try {
    // Nettoyer les backticks markdown si Gemini en ajoute malgré les instructions
    const cleaned = rawText
      .replace(/```json\s*/gi, '')
      .replace(/```\s*/gi, '')
      .trim();
    return JSON.parse(cleaned);
  } catch (e) {
    console.error('❌ Parsing JSON Gemini échoué:', e.message);
    console.error('   Texte reçu:', rawText.substring(0, 200));
    // Retourner une réponse de secours
    return {
      intent: 'unknown',
      message: rawText, // Afficher le texte brut si pas JSON
      searchTerm: null,
      action: null,
    };
  }
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

function extractSearchTermFallback(message) {
  const msg = message.toLowerCase();
  const brands = ['samsung', 'apple', 'iphone', 'huawei', 'xiaomi', 'sony', 'lg', 'nokia', 'oppo'];
  for (const brand of brands) {
    if (msg.includes(brand)) return brand;
  }
  const categories = ['smartphone', 'ordinateur', 'vêtement', 'vetement', 'sport', 'casque', 'tablette'];
  for (const cat of categories) {
    if (msg.includes(cat)) return cat;
  }
  return null;
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
    orderStatus:       '📋 Pour suivre votre commande, consultez votre email de confirmation ou contactez-nous.',
    help:              '❓ Je peux vous aider avec:\n• Rechercher des produits\n• Vérifier les prix et stocks\n• Infos de livraison\n• Suivre une commande',
    goodbye:           '👋 Au revoir ! Merci de votre visite. À bientôt !',
    unknown:           '❓ Je n\'ai pas bien compris. Pouvez-vous reformuler ? (ex: "je cherche un samsung")',
  };

  const needsProducts = ['productSearch', 'priceInquiry', 'availabilityCheck', 'categoryBrowse', 'recommendation'];
  const action = needsProducts.includes(intent) ? {
    type: 'filter',
    target: '/Products',
    params: searchTerm ? { search: searchTerm } : {},
    message: '📦 Affichage des produits...',
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
// POST /api/chatbot/process
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
        // 1. Extraire un terme de recherche rapide (pour précharger les produits pertinents)
        const quickSearch = extractSearchTermFallback(userMessage);

        // 2. Charger les produits pertinents depuis MySQL (contexte réel pour Gemini)
        const products = await loadProductsForContext(quickSearch, 8);
        console.log(`📦 [Chatbot] ${products.length} produits chargés pour le contexte Gemini`);

        // 3. Appeler Gemini avec contexte + historique conversation
        const rawGeminiResponse = await callGemini(userMessage, sessionId, products);
        console.log(`🤖 [Gemini] Réponse brute: ${rawGeminiResponse.substring(0, 150)}...`);

        // 4. Parser le JSON retourné par Gemini
        const parsed = parseGeminiResponse(rawGeminiResponse);

        // 5. Recharger les produits filtrés si Gemini a identifié un searchTerm
        let finalProducts = products;
        if (parsed.searchTerm && parsed.searchTerm !== quickSearch) {
          finalProducts = await loadProductsForContext(parsed.searchTerm, 5);
        }

        const response = {
          intent: parsed.intent ?? 'unknown',
          message: parsed.message ?? 'Je n\'ai pas compris.',
          action: parsed.action ?? null,
          products: finalProducts,
          source: 'gemini',
        };

        console.log(`✅ [Chatbot] Intent="${response.intent}" Produits=${finalProducts.length}`);
        return res.status(200).json(response);

      } catch (geminiError) {
        console.error('❌ [Gemini] Erreur:', geminiError.message);
        console.log('⚠️  Basculement vers le fallback RegEx...');
        // Continuer vers le fallback ci-dessous
      }
    }

    // ── MODE FALLBACK REGEX (si Gemini désactivé ou en erreur) ──────────────
    const intent = detectIntentFallback(userMessage);
    const searchTerm = extractSearchTermFallback(userMessage);
    const fallbackResponse = await buildFallbackResponse(intent, searchTerm);

    console.log(`⚡ [Fallback] Intent="${intent}" SearchTerm="${searchTerm}"`);
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
// DELETE /api/chatbot/session/:sessionId
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
