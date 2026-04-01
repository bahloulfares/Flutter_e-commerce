import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/theme.controller.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/utils/translation_service.dart';
import 'package:atelier7/presentation/screens/map.screen.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  SettingsWidgetState createState() => SettingsWidgetState();
}

class SettingsWidgetState extends State<SettingsWidget> {
  bool notificationsEnabled = false;
  bool locationEnabled = false;
  final ThemeController _themeController = Get.find<ThemeController>();
  final LanguageController _langController = Get.find<LanguageController>();
  final TranslationService _translationService = TranslationService();

  // Suivi du téléchargement des modèles
  final Map<String, bool> _modelDownloaded = {};
  final Map<String, bool> _modelLoading = {};

  @override
  void initState() {
    super.initState();
    _checkModels();
  }

  Future<void> _checkModels() async {
    for (final code in LanguageController.supportedLanguages.keys) {
      final downloaded = await _translationService.isModelDownloaded(code);
      if (mounted) {
        setState(() => _modelDownloaded[code] = downloaded);
      }
    }
  }

  Future<void> _downloadModel(String langCode) async {
    setState(() => _modelLoading[langCode] = true);
    try {
      // Snackbar d'info pendant le téléchargement
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Text(
                'Téléchargement ${LanguageController.supportedLanguages[langCode]}... (30 Mo, patientez)'),
          ],
        ),
        duration: const Duration(seconds: 60),
        backgroundColor: Colors.blueGrey[700],
      ));

      final ok = await _translationService.downloadModel(langCode);

      // Fermer le snackbar en cours
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
        setState(() => _modelDownloaded[langCode] = ok);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? '✅ Modèle ${LanguageController.supportedLanguages[langCode]} prêt'
              : '❌ Échec — vérifiez votre connexion internet'),
          backgroundColor: ok ? Colors.green[700] : Colors.red[700],
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red[700],
        ));
      }
    } finally {
      if (mounted) setState(() => _modelLoading[langCode] = false);
    }
  }

  Future<void> _selectLanguage(String langCode) async {
    // EN est toujours disponible sans téléchargement
    if (langCode == 'en') {
      await _langController.setLanguage(langCode);
      return;
    }

    final downloaded = _modelDownloaded[langCode] ?? false;
    if (!downloaded) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Télécharger le modèle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le modèle "${LanguageController.supportedLanguages[langCode]}" '
                'doit être téléchargé (~30 Mo).',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '⚠️ Nécessite un VPN si vous êtes en Tunisie.\n'
                  'Recommandé: ProtonVPN ou Windscribe (gratuits)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Télécharger quand même')),
          ],
        ),
      );
      if (confirm != true) return;
      await _downloadModel(langCode);
    }
    await _langController.setLanguage(langCode);
    developer.log('Langue changée: $langCode', name: 'SettingsWidget');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              // --- Langue ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Langue / Language / اللغة',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant)),
              ),
              Obx(() {
                return Column(
                  children: LanguageController.supportedLanguages.entries
                      .map((entry) {
                    final code = entry.key;
                    final label = entry.value;
                    final isSelected =
                        _langController.currentLocale.value == code;
                    final downloaded = _modelDownloaded[code] ?? false;
                    final loading = _modelLoading[code] ?? false;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isSelected
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        child: Text(
                          _flagEmoji(code),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      title: Text(label,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      subtitle: Text(
                        downloaded ? 'Modèle disponible' : 'Modèle non téléchargé',
                        style: TextStyle(
                            fontSize: 11,
                            color: downloaded ? Colors.green : cs.onSurfaceVariant),
                      ),
                      trailing: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : isSelected
                              ? Icon(Icons.check_circle, color: cs.primary)
                              : downloaded
                                  ? const Icon(Icons.radio_button_unchecked)
                                  : IconButton(
                                      icon: const Icon(Icons.download_outlined),
                                      tooltip: 'Télécharger le modèle',
                                      onPressed: () => _downloadModel(code),
                                    ),
                      onTap: () => _selectLanguage(code),
                    );
                  }).toList(),
                );
              }),

              const Divider(),

              // --- Thème ---
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                trailing: Obx(
                  () => Switch(
                    value: _themeController.isDarkMode.value,
                    onChanged: (value) async {
                      await _themeController.setDarkMode(value);
                    },
                  ),
                ),
              ),

              // --- Notifications ---
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => notificationsEnabled = value),
                ),
              ),

              // --- Localisation ---
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location services'),
                trailing: Switch(
                  value: locationEnabled,
                  onChanged: (value) =>
                      setState(() => locationEnabled = value),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('Diagnostic ML Kit'),
                subtitle: const Text('Tester le téléchargement des modèles'),
                onTap: () => Navigator.pushNamed(context, '/mlkitDiag'),
              ),
            ],
          ),
        ),
        if (locationEnabled)
          const Expanded(
            child: SizedBox(
              height: 300,
              child: MapScreen(),
            ),
          ),
      ],
    );
  }

  String _flagEmoji(String code) {
    switch (code) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇬🇧';
      case 'ar':
        return '🇹🇳';
      default:
        return '🌐';
    }
  }
}
