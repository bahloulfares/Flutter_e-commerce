import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class MlkitDiagnosticScreen extends StatefulWidget {
  const MlkitDiagnosticScreen({super.key});

  @override
  State<MlkitDiagnosticScreen> createState() => _MlkitDiagnosticScreenState();
}

class _MlkitDiagnosticScreenState extends State<MlkitDiagnosticScreen> {
  final List<String> _logs = [];
  bool _running = false;

  void _log(String msg) {
    developer.log(msg, name: 'MLKitDiag');
    if (mounted) setState(() => _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg'));
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _logs.clear();
      _running = true;
    });

    final manager = OnDeviceTranslatorModelManager();

    // --- Étape 1 : vérifier modèles existants ---
    _log('=== ÉTAPE 1: Vérification modèles existants ===');
    for (final entry in {
      'fr': TranslateLanguage.french,
      'en': TranslateLanguage.english,
      'ar': TranslateLanguage.arabic,
    }.entries) {
      try {
        final exists = await manager.isModelDownloaded(entry.value.bcpCode);
        _log('${entry.key} (${entry.value.bcpCode}): ${exists ? "✅ DÉJÀ TÉLÉCHARGÉ" : "❌ non disponible"}');
      } catch (e) {
        _log('${entry.key}: ❌ ERREUR isModelDownloaded → $e');
      }
    }

    // --- Étape 2 : tenter téléchargement FR ---
    _log('');
    _log('=== ÉTAPE 2: Téléchargement modèle FR (wifi=false) ===');
    _log('Début... (peut prendre 1-2 min)');
    try {
      final ok = await manager
          .downloadModel(TranslateLanguage.french.bcpCode, isWifiRequired: false)
          .timeout(const Duration(minutes: 3), onTimeout: () {
        _log('⏱️ TIMEOUT après 3 minutes');
        return false;
      });
      _log(ok ? '✅ Téléchargement FR réussi !' : '❌ downloadModel retourné false');
    } catch (e) {
      _log('❌ EXCEPTION downloadModel FR: $e');
      _log('Type erreur: ${e.runtimeType}');
    }

    // --- Étape 3 : tenter traduction simple ---
    _log('');
    _log('=== ÉTAPE 3: Test traduction FR→EN ===');
    try {
      final translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.french,
        targetLanguage: TranslateLanguage.english,
      );
      final result = await translator
          .translateText('Bonjour')
          .timeout(const Duration(seconds: 10), onTimeout: () => 'TIMEOUT');
      _log('Résultat: "Bonjour" → "$result"');
      await translator.close();
    } catch (e) {
      _log('❌ EXCEPTION traduction: $e');
    }

    setState(() => _running = false);
    _log('');
    _log('=== DIAGNOSTIC TERMINÉ ===');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic ML Kit'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _running ? null : _runDiagnostic,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bug_report),
              label: Text(_running ? 'Diagnostic en cours...' : 'Lancer le diagnostic'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
          if (_running)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LinearProgressIndicator(color: cs.primary),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text('Appuie sur "Lancer le diagnostic"',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (_, i) {
                        final log = _logs[i];
                        Color color = Colors.white70;
                        if (log.contains('✅')) color = Colors.greenAccent;
                        if (log.contains('❌') || log.contains('ERREUR') || log.contains('EXCEPTION')) {
                          color = Colors.redAccent;
                        }
                        if (log.contains('===')) color = Colors.yellowAccent;
                        if (log.contains('⏱️')) color = Colors.orangeAccent;
                        return Text(log,
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontFamily: 'monospace'));
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
