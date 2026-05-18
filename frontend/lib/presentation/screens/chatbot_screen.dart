import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:google_fonts/google_fonts.dart';
import 'package:atelier7/utils/chatbot_service.dart';
import 'package:atelier7/data/datasource/models/article.model.dart';
import 'package:get/get.dart';

// ── Modèle de message enrichi ─────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<dynamic> suggestedProducts; // Produits de la BDD
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

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    developer.log('🤖 CHATBOT: Démarrage', name: 'ChatbotDebug');
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Bonjour ! 👋 Je suis votre assistant shopping.\nJe peux vous aider à trouver des produits, vérifier les prix et les stocks.\nComment puis-je vous aider ?',
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: ['Voir les produits', 'Promotions', 'Aide'],
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

    try {
      final response = await _chatbotService.generateResponse(
        userMessage: text,
      );
      developer.log(
        '🤖 CHATBOT: Intent=${response.detectedIntent} Produits=${response.suggestedProducts.length}',
        name: 'ChatbotDebug',
      );

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

      // ✅ Plus de redirection automatique ! Les produits sont affichés dans le chat.
      // On propose juste un bouton "Voir tous les produits" si pertinent.

    } catch (e) {
      developer.log('❌ CHATBOT: Erreur - $e', name: 'ChatbotDebug', error: e);
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Désolé, une erreur est survenue. Veuillez réessayer.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
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
              backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
              child: Icon(Icons.smart_toy, size: 18, color: colorScheme.onPrimary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assistant'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    )),
                Text('Gemini AI • En ligne',
                    style: GoogleFonts.poppins(
                      fontSize: 11, color: colorScheme.onPrimary.withValues(alpha: 0.75),
                    )),
              ],
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator(colorScheme);
                }
                return _buildMessageBubble(_messages[index], colorScheme);
              },
            ),
          ),
          // Suggestions rapides
          if (_messages.isNotEmpty && _messages.last.quickReplies.isNotEmpty)
            _buildQuickReplies(_messages.last.quickReplies, colorScheme),
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  // ── Bulle de message ─────────────────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isUser) ...[
                CircleAvatar(
                  radius: 15,
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.smart_toy, size: 14, color: colorScheme.onPrimary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
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
                        style: GoogleFonts.poppins(
                          color: message.isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: message.isUser
                              ? colorScheme.onPrimary.withValues(alpha: 0.65)
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
                  radius: 15,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.person, size: 14, color: colorScheme.onPrimaryContainer),
                ),
              ],
            ],
          ),

          // ✅ Cartes produits affichées DIRECTEMENT sous la bulle du bot
          if (!message.isUser && message.suggestedProducts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scrollable horizontal de cartes produits
                  SizedBox(
                    height: 175,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.suggestedProducts.length,
                      itemBuilder: (ctx, i) =>
                          _buildProductCard(message.suggestedProducts[i], colorScheme),
                    ),
                  ),
                  // Bouton "Voir tous les produits" en bas des cartes
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/Products'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Voir tous les produits →',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Carte produit ─────────────────────────────────────────────────────────────
  Widget _buildProductCard(dynamic product, ColorScheme colorScheme) {
    final String designation = (product['designation'] ?? product.designation ?? 'Produit').toString();
    final String marque = (product['marque'] ?? product.marque ?? '').toString();
    final dynamic prixRaw = product['prix'] ?? product.prix ?? 0;
    final double prix = double.tryParse(prixRaw.toString()) ?? 0;
    final int stock = int.tryParse((product['qtestock'] ?? product.qtestock ?? 0).toString()) ?? 0;
    final String imageUrl = (product['imageart'] ?? product.imageart ?? '').toString();
    final bool inStock = stock > 0;

    return GestureDetector(
      onTap: () {
        try {
          // Convertir le Map dynamique en objet Article pour la page de détails
          final articleObj = Article.fromJson(product as Map<String, dynamic>);
          Navigator.pushNamed(context, '/details', arguments: articleObj);
        } catch (e) {
          developer.log('Erreur conversion produit: $e', error: e);
          // Fallback sur la liste des produits si erreur
          Navigator.pushNamed(context, '/Products');
        }
      },
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image produit
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.image_not_supported_rounded,
                              color: colorScheme.onSurfaceVariant, size: 28),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.shopping_bag_outlined,
                            color: colorScheme.onSurfaceVariant, size: 28),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (marque.isNotEmpty)
                    Text(marque,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Text(designation,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${prix.toStringAsFixed(0)} TND',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: inStock
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inStock ? '✓ Dispo' : 'Rupture',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: inStock ? const Color(0xFF10B981) : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────────────────────────
  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.smart_toy, size: 14, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildDot(i, colorScheme)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + index * 200),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, -4 * (value < 0.5 ? value : 1 - value) * 2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: index == 1 ? 4 : 0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // ── Suggestions rapides ───────────────────────────────────────────────────────
  Widget _buildQuickReplies(List<String> replies, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies
              .map((reply) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(reply,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          )),
                      onPressed: () => _sendMessage(reply),
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Zone de saisie ────────────────────────────────────────────────────────────
  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
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
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Posez votre question...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: _sendMessage,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.send_rounded, color: colorScheme.onPrimary, size: 20),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
