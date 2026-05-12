import 'dart:math';

/// Types d'intentions pour le chatbot e-commerce
enum ChatIntent {
  greeting,
  productSearch,
  priceInquiry,
  availabilityCheck,
  orderStatus,
  help,
  recommendation,
  categoryBrowse,
  delivery,
  goodbye,
  unknown,
}

/// Réponse du chatbot
class ChatResponse {
  final String message;
  final ChatIntent detectedIntent;
  final List<String> suggestedActions;
  final List<dynamic> suggestedProducts;
  final double confidence;

  ChatResponse({
    required this.message,
    required this.detectedIntent,
    this.suggestedActions = const [],
    this.suggestedProducts = const [],
    this.confidence = 0.0,
  });
}

/// Service principal du chatbot — basé sur règles locales
class ChatbotService {
  final List<_ChatMsg> _history = [];

  // ── Patterns d'intention ──────────────────────────────────────────────────
  static final Map<ChatIntent, List<RegExp>> _patterns = {
    ChatIntent.greeting: [
      RegExp(r'\b(bonjour|salut|coucou|hello|hi|bonsoir)\b', caseSensitive: false),
    ],
    ChatIntent.productSearch: [
      RegExp(r'\b(cherche|recherche|trouver|veux|voudrais|besoin)\b', caseSensitive: false),
      RegExp(r'\b(samsung|apple|iphone|huawei|xiaomi|sony|lg|nokia|asus|lenovo|dell|hp)\b', caseSensitive: false),
      RegExp(r'\b(smartphone|téléphone|telephone|portable|mobile|ordinateur|laptop|tablette|casque|écran|ecran)\b', caseSensitive: false),
      RegExp(r'\b(vêtement|vetement|chaussure|chemise|pantalon|robe|sport|fitness)\b', caseSensitive: false),
      RegExp(r'\b(montrez?|voir|afficher)\s+(les?|vos?|des?)?\s*(produits?|articles?)\b', caseSensitive: false),
    ],
    ChatIntent.priceInquiry: [
      RegExp(r'\b(combien|prix|coûte|coute|tarif|cher|pas\s+cher|moins\s+cher)\b', caseSensitive: false),
    ],
    ChatIntent.availabilityCheck: [
      RegExp(r'\b(disponible|en\s+stock|rupture|reste)\b', caseSensitive: false),
    ],
    ChatIntent.orderStatus: [
      RegExp(r'\b(commande|colis|livraison|suivi|suivre|tracking)\b', caseSensitive: false),
    ],
    ChatIntent.recommendation: [
      RegExp(r'\b(promotion|promo|réduction|reduction|solde|offre|rabais|remise)\b', caseSensitive: false),
      RegExp(r'\b(recommand|conseil|meilleur|populaire|tendance|nouveauté)\b', caseSensitive: false),
    ],
    ChatIntent.categoryBrowse: [
      RegExp(r'\b(catégorie|categorie|catalogue|liste|tous\s+les?\s+produits?)\b', caseSensitive: false),
    ],
    ChatIntent.delivery: [
      RegExp(r'\b(livraison|livrer|délai|frais\s+de\s+port|expédition)\b', caseSensitive: false),
    ],
    ChatIntent.help: [
      RegExp(r'\b(aide|aider|assistance|support|help|comment|problème|probleme)\b', caseSensitive: false),
    ],
    ChatIntent.goodbye: [
      RegExp(r'\b(au\s+revoir|bye|à\s+bientôt|bonne\s+journée|merci|ciao)\b', caseSensitive: false),
    ],
  };

  // ── Réponses par intention ────────────────────────────────────────────────
  static final Map<ChatIntent, List<String>> _responses = {
    ChatIntent.greeting: [
      "Bonjour ! Bienvenue dans notre boutique. Comment puis-je vous aider ?",
      "Salut ! Je suis votre assistant. Que recherchez-vous aujourd'hui ?",
    ],
    ChatIntent.productSearch: [
      "Je vais vous aider à trouver ce produit. Pouvez-vous préciser la marque ou le modèle ?",
      "Nous avons une large gamme de produits. Quel type vous intéresse ? (électronique, vêtements, sport...)",
      "Bonne question ! Donnez-moi plus de détails sur ce que vous cherchez.",
    ],
    ChatIntent.priceInquiry: [
      "Nos prix sont très compétitifs ! Quel produit vous intéresse pour que je vous donne le prix ?",
      "Je peux vous renseigner sur les prix. Quel article souhaitez-vous connaître ?",
    ],
    ChatIntent.availabilityCheck: [
      "Je vérifie la disponibilité. Quel produit souhaitez-vous vérifier ?",
      "Laissez-moi consulter notre stock. De quel article s'agit-il ?",
    ],
    ChatIntent.orderStatus: [
      "Pour suivre votre commande, allez dans votre profil → 'Mes commandes'. Avez-vous un numéro de commande ?",
      "Je peux vous aider avec votre commande. Consultez la section 'Commandes' dans votre profil.",
    ],
    ChatIntent.recommendation: [
      "Nous avons d'excellentes promotions en ce moment ! Consultez notre catalogue pour les offres spéciales.",
      "Voici nos meilleures offres ! Souhaitez-vous voir les promotions par catégorie ?",
    ],
    ChatIntent.categoryBrowse: [
      "Nous avons plusieurs catégories : 📱 Smartphones, 💻 Ordinateurs, 👗 Vêtements, 🏃 Sport. Laquelle vous intéresse ?",
      "Notre catalogue est varié ! Quelle catégorie souhaitez-vous explorer ?",
    ],
    ChatIntent.delivery: [
      "Nous livrons partout. Délai standard : 2-5 jours ouvrables. Les frais sont calculés au checkout.",
      "Livraison standard en 3-5 jours. Express disponible en 24-48h (frais supplémentaires).",
    ],
    ChatIntent.help: [
      "Je suis là pour vous aider ! Posez-moi des questions sur les produits, prix, commandes ou livraison.",
      "Comment puis-je vous assister ? Je peux vous aider pour la recherche de produits, le suivi de commandes, et plus.",
    ],
    ChatIntent.goodbye: [
      "Merci de votre visite ! N'hésitez pas à revenir si vous avez d'autres questions. 😊",
      "Au revoir ! Bonne journée et à bientôt sur notre boutique.",
    ],
    ChatIntent.unknown: [
      "Je n'ai pas bien compris. Pouvez-vous reformuler votre question ?",
      "Pouvez-vous être plus précis ? Je peux vous aider avec les produits, commandes, prix ou livraison.",
      "Essayez de me demander par exemple : 'Je cherche un smartphone' ou 'Quel est le prix de...'",
    ],
  };

  // ── Actions suggérées par intention ──────────────────────────────────────
  static const Map<ChatIntent, List<String>> _actions = {
    ChatIntent.greeting: ['Voir les produits', 'Promotions', 'Aide'],
    ChatIntent.productSearch: ['Voir les smartphones', 'Voir les ordinateurs', 'Voir les vêtements'],
    ChatIntent.priceInquiry: ['Voir les promotions', 'Produits populaires'],
    ChatIntent.availabilityCheck: ['Voir les produits', 'Nouveautés'],
    ChatIntent.orderStatus: ['Suivre ma commande', 'Contacter le support'],
    ChatIntent.recommendation: ['Voir les promotions', 'Nouveautés', 'Produits populaires'],
    ChatIntent.categoryBrowse: ['Voir les smartphones', 'Voir les ordinateurs', 'Voir les vêtements'],
    ChatIntent.delivery: ['Frais de livraison', 'Délais de livraison'],
    ChatIntent.help: ['Comment commander ?', 'Frais de livraison', 'Contacter le support'],
    ChatIntent.goodbye: ['Voir les produits', 'Aide'],
    ChatIntent.unknown: ['Voir les produits', 'Aide', 'Contacter le support'],
  };

  // ── Détection d'intention ─────────────────────────────────────────────────
  ChatIntent detectIntent(String message) {
    final lower = message.toLowerCase().trim();
    for (final entry in _patterns.entries) {
      for (final pattern in entry.value) {
        if (pattern.hasMatch(lower)) return entry.key;
      }
    }
    return ChatIntent.unknown;
  }

  // ── Génération de réponse ─────────────────────────────────────────────────
  Future<ChatResponse> generateResponse({
    required String userMessage,
    List<dynamic>? products,
  }) async {
    _history.add(_ChatMsg(text: userMessage, isUser: true));

    final intent = detectIntent(userMessage);
    final responses = _responses[intent] ?? _responses[ChatIntent.unknown]!;
    final message = responses[Random().nextInt(responses.length)];
    final actions = List<String>.from(_actions[intent] ?? []);

    // Produits suggérés si disponibles
    final suggested = _filterProducts(intent, userMessage, products ?? []);

    final response = ChatResponse(
      message: message,
      detectedIntent: intent,
      suggestedActions: actions,
      suggestedProducts: suggested,
      confidence: intent == ChatIntent.unknown ? 0.3 : 0.8,
    );

    _history.add(_ChatMsg(text: message, isUser: false));
    return response;
  }

  // ── Filtrage produits ─────────────────────────────────────────────────────
  List<dynamic> _filterProducts(ChatIntent intent, String message, List<dynamic> products) {
    if (products.isEmpty) return [];
    final lower = message.toLowerCase();

    final keywordMap = {
      'smartphone': ['smartphone', 'téléphone', 'iphone', 'samsung', 'mobile', 'portable'],
      'ordinateur': ['ordinateur', 'laptop', 'pc'],
      'vêtement': ['vêtement', 'chemise', 'pantalon', 'robe'],
      'sport': ['sport', 'football', 'running'],
    };

    for (final entry in keywordMap.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) {
        final filtered = products.where((p) {
          final d = (p.designation ?? '').toLowerCase();
          final m = (p.marque ?? '').toLowerCase();
          return entry.value.any((kw) => d.contains(kw) || m.contains(kw));
        }).take(4).toList();
        if (filtered.isNotEmpty) return filtered;
      }
    }

    return products.take(3).toList();
  }

  void clearHistory() => _history.clear();
}

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});
}
