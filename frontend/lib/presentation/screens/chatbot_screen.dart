import 'package:flutter/material.dart';
import 'package:atelier7/utils/chatbot_service.dart';
import 'package:atelier7/data/datasource/services/article_service.dart';
import 'package:atelier7/data/datasource/models/article.model.dart';

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
    _loadProducts();
    _addWelcomeMessage();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _articleService.getArticles();
      setState(() {
        _allProducts = products.map((json) => Article.fromJson(json)).toList();
      });
    } catch (e) {
      // Silent fail - chatbot will work without products
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
            "Bonjour ! Je suis votre assistant virtuel. Comment puis-je vous aider aujourd'hui ?",
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: [
          'Voir les produits',
          'Aide',
          'Suivre ma commande',
        ],
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate response
    final response = await _chatbotService.generateResponse(
      userMessage: text,
      products: _allProducts,
    );

    setState(() {
      _messages.add(ChatMessage(
        text: response.message,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedProducts: response.suggestedProducts,
        quickReplies: response.suggestedActions,
      ));
      _isLoading = false;
    });

    _scrollToBottom();
  }

  // Mapping des actions rapides vers des messages lisibles
  static const Map<String, String> _quickReplyMessages = {
    'Voir les smartphones': 'Je recherche des smartphones',
    'Voir les ordinateurs': 'Je recherche des ordinateurs',
    'Voir les vêtements': 'Je recherche des vêtements',
    'Voir les articles de sport': 'Je recherche des articles de sport',
    'Voir les promotions': 'Quels sont les produits en promotion ?',
    'Voir les produits': 'Montrez-moi vos produits',
    'Suivre ma commande': 'Je veux suivre ma commande',
    'Comment commander ?': 'Comment passer une commande ?',
    'Frais de livraison': 'Quels sont les frais de livraison ?',
    'Aide': 'J\'ai besoin d\'aide',
    'Contacter le support': 'Je veux contacter le support',
    'Historique des commandes': 'Voir mon historique de commandes',
    'Nouveautés': 'Voir les nouveautés',
    'Produits populaires': 'Voir les produits populaires',
    'Délais de livraison': 'Quels sont les délais de livraison ?',
  };

  void _handleQuickReply(String action) {
    final userMessage = _quickReplyMessages[action] ?? action;
    _sendMessageWithDisplay(action: action, userMessage: userMessage);
  }

  Future<void> _sendMessageWithDisplay({
    required String action,
    required String userMessage,
  }) async {
    // Affiche le label du bouton dans la bulle utilisateur
    setState(() {
      _messages.add(ChatMessage(
        text: action,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Génère la réponse avec le message traduit (pour une meilleure détection)
    final response = await _chatbotService.generateResponse(
      userMessage: userMessage,
      products: _allProducts,
    );

    setState(() {
      _messages.add(ChatMessage(
        text: response.message,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedProducts: response.suggestedProducts,
        quickReplies: response.suggestedActions,
      ));
      _isLoading = false;
    });

    _scrollToBottom();
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
              child:
                  Icon(Icons.smart_toy, size: 20, color: colorScheme.onPrimary),
            ),
            const SizedBox(width: 8),
            const Text('Assistant Virtuel'),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'À propos',
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
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

          // Quick replies (if last message has them)
          if (_messages.isNotEmpty && _messages.last.quickReplies.isNotEmpty)
            _buildQuickReplies(_messages.last.quickReplies),

          // Input area
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child:
                  Icon(Icons.smart_toy, size: 16, color: colorScheme.onPrimary),
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
              child: Icon(Icons.person,
                  size: 16, color: colorScheme.onPrimaryContainer),
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
            child: Icon(Icons.smart_toy,
                size: 16, color: Theme.of(context).colorScheme.onPrimary),
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
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
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
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
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
          children: replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(reply),
                onPressed: () => _handleQuickReply(reply),
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
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
                  hintText: 'Écrivez votre message...',
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
        title: const Text('Assistant Virtuel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Je suis votre assistant intelligent pour vous aider dans vos achats.',
            ),
            const SizedBox(height: 16),
            const Text('Je peux vous aider avec :'),
            const SizedBox(height: 8),
            _buildFeatureItem(Icons.search, 'Recherche de produits'),
            _buildFeatureItem(Icons.attach_money, 'Informations sur les prix'),
            _buildFeatureItem(Icons.inventory_2, 'Vérification de stock'),
            _buildFeatureItem(Icons.local_shipping, 'Suivi de commandes'),
            _buildFeatureItem(Icons.help, 'Support client'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
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
