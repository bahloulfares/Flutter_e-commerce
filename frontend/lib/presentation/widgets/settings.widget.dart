import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/theme.controller.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/presentation/screens/face_capture_screen.dart';
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
  final AuthController _authController = Get.find<AuthController>();
  final TranslationService _translationService = TranslationService();

  final Map<String, bool> _modelDownloaded = {};
  final Map<String, bool> _modelLoading = {};

  // État biométrie séparé
  bool _fingerprintAvailable = false;
  bool _faceAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkModels();
    _checkBiometricTypes();
  }

  Future<void> _checkBiometricTypes() async {
    await _authController.checkBiometricAvailability();
    final bs = _authController.biometricService;
    final fp = await bs.isFingerprintAvailable();
    final cameras = await availableCameras();
    final faceCameraAvailable = cameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    developer.log(
        '🔍 fp=$fp faceCamera=$faceCameraAvailable available=${_authController.isBiometricAvailable.value}',
        name: 'SettingsWidget');
    if (mounted) {
      setState(() {
        _faceAvailable = faceCameraAvailable;
        // L'empreinte ne dépend pas de la caméra frontale ni de Face ID ML Kit.
        // Sur certains appareils, local_auth ne remonte pas toujours le capteur.
        _fingerprintAvailable =
            fp || _authController.isBiometricAvailable.value;
      });
    }
  }

  Future<void> _showEnableBiometricDialog(ColorScheme cs,
      {String type = 'biometrie'}) async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    final icon = type == 'face' ? Icons.face : Icons.fingerprint;
    final title = type == 'face' ? 'Activer Face ID' : 'Activer l\'empreinte';
    final instruction = type == 'face'
        ? '⚠️ Assurez-vous d\'avoir configuré la reconnaissance faciale dans Paramètres Android → Sécurité → Reconnaissance faciale.'
        : '⚠️ Assurez-vous d\'avoir enregistré votre empreinte dans Paramètres Android → Sécurité → Empreinte digitale.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: Colors.purple),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(instruction, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 12),
              const Text('Entrez vos identifiants pour confirmer :',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon:
                        Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
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
                child: const Text('Activer')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await _authController.enableBiometric(
        emailCtrl.text.trim(), passwordCtrl.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '✅ ${type == 'face' ? 'Face ID' : 'Empreinte'} activé(e) avec succès'
          : '❌ Identifiants invalides ou biométrie non disponible'),
      backgroundColor: ok ? Colors.green[700] : Colors.red[700],
    ));
  }

  /// Dialog spécifique pour activation Face ID ML Kit avec capture caméra
  Future<void> _showEnableFaceIdMlKitDialog(ColorScheme cs) async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.face, color: Colors.purple),
              SizedBox(width: 8),
              Text('Activer Face ID ML Kit'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✅ Recognition précise basée sur les landmarks du visage\n'
                  '📸 Vous verrez un écran de capture pour enregistrer votre visage\n'
                  '🔐 Les données du visage sont stockées localement sécurisé',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Vérifiez vos identifiants :',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon:
                        Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
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
                child: const Text('Continuer')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Vérifier les credentials
      final credOk = await _authController.enableFaceIdMlKit(
        emailCtrl.text.trim(),
        passwordCtrl.text,
      );

      if (!mounted) return;

      if (!credOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Identifiants invalides'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Credentials OK → lancer la capture du visage pour l'enregistrement
      if (!mounted) return;
      final enrolled = await Navigator.of(context).pushNamed(
        '/faceCapture',
        arguments: FaceCaptureMode.enroll,
      );

      if (mounted) {
        if (enrolled == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Face ID ML Kit activé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // L'utilisateur a annulé l'enregistrement → désactiver Face ID
          await _authController.disableFaceIdMlKit();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enregistrement du visage annulé'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

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
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
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
                child: Text('langue'.tr,
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
                    final isChanging = _langController.isLanguageChanging.value;
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
                        downloaded
                            ? 'Modèle disponible'
                            : 'Modèle non téléchargé',
                        style: TextStyle(
                            fontSize: 11,
                            color: downloaded
                                ? Colors.green
                                : cs.onSurfaceVariant),
                      ),
                      trailing: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : (isSelected && isChanging)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : isSelected
                                  ? Icon(Icons.check_circle, color: cs.primary)
                                  : downloaded
                                      ? const Icon(Icons.radio_button_unchecked)
                                      : IconButton(
                                          icon: const Icon(
                                              Icons.download_outlined),
                                          tooltip: 'Télécharger le modèle',
                                          onPressed: () => _downloadModel(code),
                                        ),
                      onTap: isChanging ? null : () => _selectLanguage(code),
                    );
                  }).toList(),
                );
              }),

              const Divider(),

              // ── SECTION EMPREINTE DIGITALE ──────────────────────────────
              Obx(() {
                final enabled = _authController.isBiometricEnabled.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text('Empreinte digitale',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'L\'empreinte utilise la biométrie native Android, séparée de Face ID ML Kit.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Explication
                    if (!_fingerprintAvailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange[700], size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Empreinte native non détectée automatiquement.\nSi votre téléphone a un capteur, le mode empreinte peut quand même fonctionner.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ListTile(
                      leading: Icon(Icons.fingerprint,
                          color: _fingerprintAvailable
                              ? (enabled ? cs.primary : cs.onSurfaceVariant)
                              : Colors.grey,
                          size: 28),
                      title: const Text('Connexion par empreinte'),
                      subtitle: Text(
                        !_fingerprintAvailable
                            ? 'Non disponible — enregistrez une empreinte dans Android'
                            : enabled
                                ? 'Activée ✓'
                                : 'Désactivée',
                        style: TextStyle(
                          fontSize: 12,
                          color: !_fingerprintAvailable
                              ? Colors.grey
                              : enabled
                                  ? Colors.green
                                  : cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: Switch(
                        value: enabled && _fingerprintAvailable,
                        onChanged: _fingerprintAvailable
                            ? (value) async {
                                if (value) {
                                  await _showEnableBiometricDialog(cs,
                                      type: 'empreinte');
                                } else {
                                  await _authController.disableBiometric();
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Empreinte désactivée')));
                                  }
                                }
                              }
                            : null,
                      ),
                    ),
                    const Divider(),
                  ],
                );
              }),

              // ── SECTION FACE ID ML KIT ──────────────────────────────────
              Obx(() {
                final enabled = _authController.isFaceIdMlKitEnabled.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text('Face ID ML Kit',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant)),
                    ),
                    // Explication
                    if (!_faceAvailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[700], size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Face ID ML Kit nécessite la caméra frontale.\nSi elle est indisponible, vérifiez les permissions caméra.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ListTile(
                      leading: Icon(Icons.face,
                          color: _faceAvailable
                              ? (enabled ? cs.primary : cs.onSurfaceVariant)
                              : Colors.grey,
                          size: 28),
                      title: const Text('Face ID ML Kit'),
                      subtitle: Text(
                        !_faceAvailable
                            ? 'Non disponible — caméra frontale requise'
                            : enabled
                                ? 'Activé ✓'
                                : 'Désactivé',
                        style: TextStyle(
                          fontSize: 12,
                          color: !_faceAvailable
                              ? Colors.grey
                              : enabled
                                  ? Colors.green
                                  : cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: Switch(
                        value: enabled && _faceAvailable,
                        onChanged: _faceAvailable
                            ? (value) async {
                                if (value) {
                                  await _showEnableFaceIdMlKitDialog(cs);
                                } else {
                                  await _authController.disableFaceIdMlKit();
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Face ID ML Kit désactivé')));
                                  }
                                }
                              }
                            : null,
                      ),
                    ),
                    const Divider(),
                  ],
                );
              }),

              // --- Thème ---
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text('dark_mode'.tr),
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
                title: Text('notifications'.tr),
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => notificationsEnabled = value),
                ),
              ),

              // --- Localisation ---
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text('localisation'.tr),
                trailing: Switch(
                  value: locationEnabled,
                  onChanged: (value) => setState(() => locationEnabled = value),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.info),
                title: Text('about'.tr),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: Text('diagnostic_mlkit'.tr),
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
