import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:atelier7/utils/chatbot_service.dart';
import 'package:atelier7/utils/chat_action.dart';
import 'package:atelier7/data/datasource/services/article_service.dart';
import 'package:atelier7/data/datasource/models/article.model.dart';
import 'package:get/get.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<dynamic> suggestedProducts;
  final List<String> quickReplies;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedProducts = const [],
    this.quickReplies = const [],
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  final ArticleService _articleService = ArticleService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<Article> _allProducts = [];

  @override
  void initState() {
    super.initState();
    developer.log('🤖 CHATBOT: Démarrage', name: 'ChatbotDebug');
    _loadProducts();
    _addWelcomeMessage();
  }

  Future<void> _loadProducts() async {
    try {
      developer.log('📦 CHATBOT: Chargement produits...', name: 'ChatbotDebug');
      final products = await _articleService.getArticles();
      developer.log(
        '✅ CHATBOT: ${products.length} produits reçus',
        name: 'ChatbotDebug',
      );
      setState(() {
        _allProducts = products.map((json) => Article.fromJson(json)).toList();
        developer.log(
          '✅ CHATBOT: ${_allProducts.length} convertis',
          name: 'ChatbotDebug',
        );
      });
    } catch (e) {
      developer.log(
        '❌ CHATBOT: Erreur produits - $e',
        name: 'ChatbotDebug',
        error: e,
      );
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'chatbot_welcome'.tr,
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: ['Voir les produits', 'Aide', 'Suivre ma commande'],
        ),
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    developer.log('💬 CHATBOT: "$text"', name: 'ChatbotDebug');
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final response = await _chatbotService.generateResponse(
        userMessage: text,
        products: _allProducts,
      );
      developer.log(
        '🤖 CHATBOT: Intent=${response.detectedIntent}',
        name: 'ChatbotDebug',
      );

      // ✅ Ajouter le message du bot
      setState(() {
        _messages.add(
          ChatMessage(
            text: response.message,
            isUser: false,
            timestamp: DateTime.now(),
            suggestedProducts: response.suggestedProducts,
            quickReplies: response.suggestedActions,
          ),
        );
        _isLoading = false;
      });

      // ✅ Exécuter l'action si elle existe (redirection, etc)
      if (response.action != null) {
        await _handleChatAction(response.action!);
      }
    } catch (e) {
      developer.log('❌ CHATBOT: Erreur - $e', name: 'ChatbotDebug', error: e);
      setState(() {
        _messages.add(
          ChatMessage(
            text: '${'erreur'.tr}: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Map<String, String> get _quickReplyMessages => {
    'Voir les smartphones': 'chat_qr_smartphones'.tr,
    'Voir les ordinateurs': 'chat_qr_computers'.tr,
    'Voir les vêtements': 'chat_qr_clothes'.tr,
    'Voir les articles de sport': 'chat_qr_sports'.tr,
    'Voir les promotions': 'chat_qr_promotions'.tr,
    'Voir les produits': 'chat_qr_products'.tr,
    'Suivre ma commande': 'chat_qr_track_order'.tr,
    'Comment commander ?': 'chat_qr_how_to_order'.tr,
    'Frais de livraison': 'chat_qr_shipping_fees'.tr,
    'Aide': 'chat_qr_help'.tr,
    'Contacter le support': 'chat_qr_contact_support'.tr,
    'Historique des commandes': 'chat_qr_order_history'.tr,
    'Nouveautés': 'chat_qr_new_items'.tr,
    'Produits populaires': 'chat_qr_popular_products'.tr,
    'Délais de livraison': 'chat_qr_delivery_time'.tr,
  };

  void _handleQuickReply(String action) {
    final msg = _quickReplyMessages[action] ?? action;
    _sendMessage(msg);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✅ Gérer les actions du chatbot (redirections, etc)
  Future<void> _handleChatAction(ChatAction action) async {
    developer.log(
      '🎯 Action chatbot: ${action.type} -> ${action.target}',
      name: 'ChatbotDebug',
    );

    try {
      switch (action.type) {
        case ActionType.redirect:
          // Redirection simple vers une page
          if (action.target != null) {
            developer.log(
              '🔀 Redirection vers: ${action.target}',
              name: 'ChatbotDebug',
            );
            Navigator.pushNamed(context, action.target!);
          }
          break;

        case ActionType.filter:
          // Navigation vers Products avec filtres
          if (action.target == '/Products' && action.params != null) {
            developer.log(
              '🔍 Filtre produits: ${action.params}',
              name: 'ChatbotDebug',
            );
            Navigator.pushNamed(context, action.target!);
          } else if (action.target != null) {
            Navigator.pushNamed(context, action.target!);
          }
          break;

        case ActionType.url:
          // Ouvrir une URL externe
          if (action.target != null) {
            developer.log(
              '🌐 Ouverture URL: ${action.target}',
              name: 'ChatbotDebug',
            );
            // Vous pouvez utiliser url_launcher pour ouvrir des URL
            // launch(action.target!);
          }
          break;

        case ActionType.message:
          // Message seul, aucune action
          developer.log('💬 Message action', name: 'ChatbotDebug');
          break;
      }
    } catch (e) {
      developer.log(
        '❌ Erreur execution action: $e',
        name: 'ChatbotDebug',
        error: e,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text('Assistant'.tr),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'about'.tr,
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text('chatbot_starting'.tr),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index], colorScheme);
                    },
                  ),
          ),
          if (_messages.isNotEmpty && _messages.last.quickReplies.isNotEmpty)
            _buildQuickReplies(_messages.last.quickReplies),
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser
                          ? colorScheme.onPrimary.withAlpha(178)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.smart_toy,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + delay * 200),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * value),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: delay == 1 ? 4 : 0),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies(List<String> replies) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies
              .map(
                (reply) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(reply),
                    onPressed: () => _handleQuickReply(reply),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'write_message'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _sendMessage,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: IconButton(
                icon: Icon(Icons.send, color: colorScheme.onPrimary),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assistant'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('chat_about_intro'.tr),
            const SizedBox(height: 16),
            Text('chat_about_help_with'.tr),
            const SizedBox(height: 8),
            _buildFeatureItem(Icons.search, 'chat_feature_search'.tr),
            _buildFeatureItem(Icons.attach_money, 'chat_feature_price'.tr),
            _buildFeatureItem(Icons.inventory_2, 'chat_feature_stock'.tr),
            _buildFeatureItem(Icons.local_shipping, 'chat_feature_tracking'.tr),
            _buildFeatureItem(Icons.help, 'chat_feature_support'.tr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
