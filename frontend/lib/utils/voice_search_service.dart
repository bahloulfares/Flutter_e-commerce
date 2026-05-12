import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:developer' as developer;

/// Service de reconnaissance vocale pour la recherche
class VoiceSearchService {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  bool _isInitialized = false;

  // Callback pour les mises à jour en temps réel
  final Function(String)? onPartialResult;
  final Function(String)? onResult;
  final Function(bool)? onListeningChanged;
  final Function(String)? onError;

  VoiceSearchService({
    this.onPartialResult,
    this.onResult,
    this.onListeningChanged,
    this.onError,
  }) {
    _speech = stt.SpeechToText();
  }

  /// Initialise le service de reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final available = await _speech.initialize();
      _isInitialized = available;
      developer.log('🎤 Voice search initialized: $available',
          name: 'VoiceSearchService');
      return available;
    } catch (e) {
      developer.log('❌ Voice search initialization failed: $e',
          name: 'VoiceSearchService');
      return false;
    }
  }

  /// Vérifie si la reconnaissance vocale est disponible
  bool get isAvailable => _speech.isAvailable;

  /// Commence l'écoute
  Future<bool> startListening({
    String localeId = 'fr_FR',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
    int partialResults = 20,
    bool cancelOnError = true,
  }) async {
    if (_isListening) {
      developer.log('⚠️ Already listening', name: 'VoiceSearchService');
      return true;
    }

    // Initialise si nécessaire
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _handleError('Reconnaissance vocale non disponible');
        return false;
      }
    }

    if (!_speech.isAvailable) {
      _handleError('Reconnaissance vocale non disponible');
      return false;
    }

    try {
      _isListening = true;
      onListeningChanged?.call(true);

      // Liste des locales supportées
      final locales = await _speech.locales();
      developer.log('🎤 Available locales: ${locales.length}',
          name: 'VoiceSearchService');

      final started = await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: cancelOnError,
        listenMode: stt.ListenMode.confirmation,
        localeId: localeId,
      );

      if (!started) {
        _isListening = false;
        onListeningChanged?.call(false);
        _handleError('Échec du démarrage de l\'écoute');
        return false;
      }

      developer.log('🎤 Started listening', name: 'VoiceSearchService');
      return true;
    } catch (e) {
      _isListening = false;
      onListeningChanged?.call(false);
      _handleError('Erreur lors du démarrage: $e');
      return false;
    }
  }

  /// Arrête l'écoute
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      onListeningChanged?.call(false);
      developer.log('🎤 Stopped listening', name: 'VoiceSearchService');

      // Retourne le résultat final
      if (_lastWords.isNotEmpty) {
        onResult?.call(_lastWords);
      }
    } catch (e) {
      developer.log('❌ Error stopping: $e', name: 'VoiceSearchService');
    }
  }

  /// Gère les résultats de reconnaissance
  void _onSpeechResult(dynamic result) {
    _lastWords = result.recognizedWords;

    if (result.finalResult) {
      developer.log('🎤 Final result: "$_lastWords"',
          name: 'VoiceSearchService');
      onResult?.call(_lastWords);
      stopListening();
    } else {
      developer.log('🎤 Partial result: "$_lastWords"',
          name: 'VoiceSearchService');
      onPartialResult?.call(_lastWords);
    }
  }

  /// Gère les erreurs
  void _handleError(String error) {
    developer.log('❌ Voice search error: $error', name: 'VoiceSearchService');
    _isListening = false;
    onListeningChanged?.call(false);
    onError?.call(error);
  }

  /// Statut de l'écoute
  bool get isListening => _isListening;

  /// Derniers mots reconnus
  String get lastWords => _lastWords;

  /// Réinitialise le service
  void reset() {
    _lastWords = '';
    _isListening = false;
  }

  /// Nettoie les ressources
  void dispose() {
    if (_isListening) {
      stopListening();
    }
    _speech = stt.SpeechToText();
    _isInitialized = false;
  }
}

/// Modèle pour les résultats de recherche vocale
class VoiceSearchResult {
  final String query;
  final bool success;
  final String? error;
  final DateTime timestamp;

  VoiceSearchResult({
    required this.query,
    required this.success,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'success': success,
        'error': error,
        'timestamp': timestamp.toIso8601String(),
      };
}
