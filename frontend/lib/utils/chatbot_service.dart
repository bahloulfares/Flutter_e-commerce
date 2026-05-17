import 'dart:math';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'chat_action.dart';
// For BASE_URL

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
  final ChatAction? action; // Optional action for navigation/redirects

  ChatResponse({
    required this.message,
    required this.detectedIntent,
    this.suggestedActions = const [],
    this.suggestedProducts = const [],
    this.confidence = 0.0,
    this.action,
  });
}

/// Service principal du chatbot — basé sur règles locales
class ChatbotService {
  final List<_ChatMsg> _history = [];

  // ── Patterns d'intention ──────────────────────────────────────────────────
  static final Map<ChatIntent, List<RegExp>> _patterns = {
    ChatIntent.greeting: [
      RegExp(
        r'\b(bonjour|salut|coucou|hello|hi|bonsoir)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.productSearch: [
      RegExp(
        r'\b(cherche|recherche|trouver|veux|voudrais|besoin)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(samsung|apple|iphone|huawei|xiaomi|sony|lg|nokia|asus|lenovo|dell|hp)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(smartphone|téléphone|telephone|portable|mobile|ordinateur|laptop|tablette|casque|écran|ecran)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(vêtement|vetement|chaussure|chemise|pantalon|robe|sport|fitness)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(montrez?|voir|afficher)\s+(les?|vos?|des?)?\s*(produits?|articles?)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.priceInquiry: [
      RegExp(
        r'\b(combien|prix|coûte|coute|tarif|cher|pas\s+cher|moins\s+cher)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.availabilityCheck: [
      RegExp(
        r'\b(disponible|en\s+stock|rupture|reste)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.orderStatus: [
      RegExp(
        r'\b(commande|colis|livraison|suivi|suivre|tracking)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.recommendation: [
      RegExp(
        r'\b(promotion|promo|réduction|reduction|solde|offre|rabais|remise)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(recommand|conseil|meilleur|populaire|tendance|nouveauté)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.categoryBrowse: [
      RegExp(
        r'\b(catégorie|categorie|catalogue|liste|tous\s+les?\s+produits?)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.delivery: [
      RegExp(
        r'\b(livraison|livrer|délai|frais\s+de\s+port|expédition)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.help: [
      RegExp(
        r'\b(aide|aider|assistance|support|help|comment|problème|probleme)\b',
        caseSensitive: false,
      ),
    ],
    ChatIntent.goodbye: [
      RegExp(
        r'\b(au\s+revoir|bye|à\s+bientôt|bonne\s+journée|merci|ciao)\b',
        caseSensitive: false,
      ),
    ],
  };

  // ── Réponses par intention ────────────────────────────────────────────────
  static final Map<ChatIntent, List<String>> _responses = {
    ChatIntent.greeting: [
      "Bonjour ! Bienvenue dans notre boutique. Comment puis-je vous aider ?",
      "Salut ! Je suis votre assistant. Que recherchez-vous aujourd'hui ?",
    ],
    ChatIntent.productSearch: [
      "✅ Voici nos produits disponibles!",
      "✅ Consultez les produits trouvés ci-dessous!",
      "✅ Désolé, voici ce que nous avons dans cette catégorie",
    ],
    ChatIntent.priceInquiry: [
      "💰 Nos prix sont très compétitifs ! Voici ce que nous avons en stock:",
      "💰 Consultez les prix de nos produits ci-dessus!",
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
    ChatIntent.productSearch: [
      'Voir les smartphones',
      'Voir les ordinateurs',
      'Voir les vêtements',
    ],
    ChatIntent.priceInquiry: ['Voir les promotions', 'Produits populaires'],
    ChatIntent.availabilityCheck: ['Voir les produits', 'Nouveautés'],
    ChatIntent.orderStatus: ['Suivre ma commande', 'Contacter le support'],
    ChatIntent.recommendation: [
      'Voir les promotions',
      'Nouveautés',
      'Produits populaires',
    ],
    ChatIntent.categoryBrowse: [
      'Voir les smartphones',
      'Voir les ordinateurs',
      'Voir les vêtements',
    ],
    ChatIntent.delivery: ['Frais de livraison', 'Délais de livraison'],
    ChatIntent.help: [
      'Comment commander ?',
      'Frais de livraison',
      'Contacter le support',
    ],
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

  // ── Génération de réponse (appel backend) ────────────────────────────────
  Future<ChatResponse> generateResponse({
    required String userMessage,
    List<dynamic>? products,
  }) async {
    _history.add(_ChatMsg(text: userMessage, isUser: true));

    try {
      // ✅ Appeler le endpoint backend
      final response = await _callBackendChatbot(userMessage);

      if (response == null) {
        // Fallback en cas d'erreur
        return _buildLocalResponse(userMessage, products);
      }

      // Parser la réponse
      final intent = _stringToIntent(response['intent'] ?? 'unknown');
      final message = response['message'] ?? 'Désolé, je n\'ai pas compris.';
      final responseProducts = response['products'] ?? [];

      // Parse l'action si elle existe
      ChatAction? action;
      if (response['action'] != null) {
        try {
          action = ChatAction.fromJson(response['action']);
        } catch (e) {
          developer.log('❌ Erreur parsing action: $e');
        }
      }

      final chatResponse = ChatResponse(
        message: message,
        detectedIntent: intent,
        suggestedActions: [],
        suggestedProducts: responseProducts,
        confidence: intent == ChatIntent.unknown ? 0.3 : 0.85,
        action: action,
      );

      _history.add(_ChatMsg(text: message, isUser: false));
      return chatResponse;
    } catch (e) {
      developer.log('❌ Erreur generateResponse: $e');
      // Fallback à la logique locale
      return _buildLocalResponse(userMessage, products);
    }
  }

  // ── Appel au backend ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _callBackendChatbot(String userMessage) async {
    try {
      // Configuration de l'URL
      const String apiUrl = 'http://192.168.100.139:3001/api/chatbot/process';

      developer.log('🌐 Appel backend: $apiUrl avec message: "$userMessage"');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'userMessage': userMessage}),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              developer.log('⏱️ Timeout backend chatbot');
              throw Exception('Backend timeout');
            },
          );

      developer.log('📡 Réponse backend: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('✅ Réponse backend OK: ${data['intent']}');
        return data;
      } else {
        developer.log('❌ Status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('❌ Erreur appel backend: $e');
      return null;
    }
  }

  // ── Conversion string → ChatIntent ────────────────────────────────────────
  ChatIntent _stringToIntent(String intentStr) {
    try {
      return ChatIntent.values.firstWhere(
        (e) => e.toString().split('.').last == intentStr,
        orElse: () => ChatIntent.unknown,
      );
    } catch (_) {
      return ChatIntent.unknown;
    }
  }

  // ── Fallback locale en cas d'erreur backend ──────────────────────────────
  ChatResponse _buildLocalResponse(
    String userMessage,
    List<dynamic>? products,
  ) {
    final intent = detectIntent(userMessage);
    final responses = _responses[intent] ?? _responses[ChatIntent.unknown]!;
    final message = responses[Random().nextInt(responses.length)];
    final actions = List<String>.from(_actions[intent] ?? []);

    final suggested = _filterProducts(intent, userMessage, products ?? []);

    String finalMessage = message;
    if (suggested.isNotEmpty &&
        (intent == ChatIntent.priceInquiry ||
            intent == ChatIntent.productSearch)) {
      finalMessage = _buildMessageWithProducts(message, suggested, intent);
    }

    return ChatResponse(
      message: finalMessage,
      detectedIntent: intent,
      suggestedActions: actions,
      suggestedProducts: suggested,
      confidence: intent == ChatIntent.unknown ? 0.3 : 0.8,
    );
  }

  // 🔥 NOUVEAU: Construire un message avec les détails des produits
  String _buildMessageWithProducts(
    String baseMessage,
    List<dynamic> products,
    ChatIntent intent,
  ) {
    if (products.isEmpty) return baseMessage;

    StringBuffer sb = StringBuffer();
    sb.writeln(baseMessage);
    sb.writeln('\n📦 Produits trouvés:');

    for (int i = 0; i < products.length && i < 5; i++) {
      final p = products[i];
      final designation = p.designation ?? 'Sans nom';
      final marque = p.marque ?? '';
      final prix = p.prix ?? '?';
      final stock = p.qtestock ?? 0;

      sb.writeln('${i + 1}. $designation');
      if (marque.isNotEmpty) sb.writeln('   Marque: $marque');
      sb.writeln('   💰 Prix: $prix DA');
      if (intent == ChatIntent.availabilityCheck) {
        sb.writeln('   📊 Stock: $stock unités');
      }
    }

    return sb.toString();
  }

  // 🔥 AMÉLIORATION: Filtrage intelligent des produits
  List<dynamic> _filterProducts(
    ChatIntent intent,
    String message,
    List<dynamic> products,
  ) {
    if (products.isEmpty) return [];
    final lower = message.toLowerCase();

    // 🔥 Chercher par marque D'ABORD (plus spécifique)
    final brands = [
      'samsung',
      'apple',
      'iphone',
      'huawei',
      'xiaomi',
      'sony',
      'lg',
      'nokia',
    ];
    for (final brand in brands) {
      if (lower.contains(brand)) {
        final filtered = products.where((p) {
          final m = (p.marque ?? '').toLowerCase();
          return m.contains(brand);
        }).toList();
        if (filtered.isNotEmpty) return filtered.take(5).toList();
      }
    }

    // 🔥 Chercher par catégorie/type de produit
    final categoryMap = {
      'smartphone': ['smartphone', 'téléphone', 'iphone', 'mobile', 'portable'],
      'ordinateur': ['ordinateur', 'laptop', 'pc', 'computer'],
      'vêtement': [
        'vêtement',
        'vetement',
        'chemise',
        'pantalon',
        'robe',
        'tee',
        't-shirt',
      ],
      'sport': ['sport', 'football', 'running', 'basket'],
      'accessoire': ['casque', 'ecran', 'écran', 'cable', 'chargeur'],
    };

    for (final entry in categoryMap.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) {
        final filtered = products.where((p) {
          final d = (p.designation ?? '').toLowerCase();
          return entry.value.any((kw) => d.contains(kw));
        }).toList();
        if (filtered.isNotEmpty) return filtered.take(5).toList();
      }
    }

    // 🔥 Par défaut: retourner les premiers produits
    return products.take(5).toList();
  }

  void clearHistory() => _history.clear();
}

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});
}
