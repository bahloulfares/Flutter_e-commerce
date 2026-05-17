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
      name: 'SettingsWidget',
    );
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

  Future<void> _showEnableBiometricDialog(
    ColorScheme cs, {
    String type = 'biometrie',
  }) async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    final icon = type == 'face' ? Icons.face : Icons.fingerprint;
    final titleKey = type == 'face'
        ? 'enable_face_id_title'
        : 'enable_fingerprint_title';
    final instructionKey = type == 'face'
        ? 'face_id_setup_warning'
        : 'fingerprint_setup_warning';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: Colors.purple),
              const SizedBox(width: 8),
              Text(titleKey.tr),
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
                child: Text(
                  instructionKey.tr,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'enter_credentials_confirm'.tr,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email'.tr,
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
                  labelText: 'Mot de passe'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('activate'.tr),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await _authController.enableBiometric(
      emailCtrl.text.trim(),
      passwordCtrl.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (type == 'face'
                    ? 'face_id_enabled_success'.tr
                    : 'fingerprint_enabled_success'.tr)
              : 'biometric_credentials_or_unavailable'.tr,
        ),
        backgroundColor: ok ? Colors.green[700] : Colors.red[700],
      ),
    );
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
          title: Row(
            children: [
              const Icon(Icons.face, color: Colors.purple),
              const SizedBox(width: 8),
              Text('face_id_mlkit_title'.tr),
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
                child: Text(
                  'face_id_mlkit_description'.tr,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'verify_credentials'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'email'.tr,
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
                  labelText: 'password'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('continue'.tr),
            ),
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
          SnackBar(
            content: Text('invalid_credentials'.tr),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Credentials OK → lancer la capture du visage pour l'enregistrement
      if (!mounted) return;
      final enrolled = await Navigator.of(
        context,
      ).pushNamed('/faceCapture', arguments: FaceCaptureMode.enroll);

      if (mounted) {
        if (enrolled == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('face_id_mlkit_enabled_success'.tr),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // L'utilisateur a annulé l'enregistrement → désactiver Face ID
          await _authController.disableFaceIdMlKit();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('face_capture_cancelled'.tr),
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
            content: Text('${'erreur'.tr}: $e'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'downloading_model'.tr.replaceAll(
                  '{lang}',
                  LanguageController.supportedLanguages[langCode] ?? langCode,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 60),
          backgroundColor: Colors.blueGrey[700],
        ),
      );

      final ok = await _translationService.downloadModel(langCode);

      // Fermer le snackbar en cours
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (mounted) {
        setState(() => _modelDownloaded[langCode] = ok);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'model_ready'.tr.replaceAll(
                      '{lang}',
                      LanguageController.supportedLanguages[langCode] ??
                          langCode,
                    )
                  : 'model_failed'.tr,
            ),
            backgroundColor: ok ? Colors.green[700] : Colors.red[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'erreur'.tr}: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
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
          title: Text('download_model_prompt'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'model_download_required'.tr.replaceAll(
                  '{lang}',
                  LanguageController.supportedLanguages[langCode] ?? langCode,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  'vpn_required_note'.tr,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('annuler'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('download_anyway'.tr),
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'langue'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Obx(() {
                return Column(
                  children: LanguageController.supportedLanguages.entries.map((
                    entry,
                  ) {
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
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        downloaded
                            ? 'model_available'.tr
                            : 'model_not_downloaded'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: downloaded
                              ? Colors.green
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (isSelected && isChanging)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : isSelected
                          ? Icon(Icons.check_circle, color: cs.primary)
                          : downloaded
                          ? const Icon(Icons.radio_button_unchecked)
                          : IconButton(
                              icon: const Icon(Icons.download_outlined),
                              tooltip: 'download_model'.tr,
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'fingerprint_section_title'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'fingerprint_section_description'.tr,
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
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'fingerprint_native_hint'.tr,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ListTile(
                      leading: Icon(
                        Icons.fingerprint,
                        color: _fingerprintAvailable
                            ? (enabled ? cs.primary : cs.onSurfaceVariant)
                            : Colors.grey,
                        size: 28,
                      ),
                      title: Text('fingerprint_connection_title'.tr),
                      subtitle: Text(
                        !_fingerprintAvailable
                            ? 'fingerprint_not_available_status'.tr
                            : enabled
                            ? 'fingerprint_enabled_status'.tr
                            : 'fingerprint_disabled_status'.tr,
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
                                  await _showEnableBiometricDialog(
                                    cs,
                                    type: 'empreinte',
                                  );
                                } else {
                                  await _authController.disableBiometric();
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'fingerprint_disabled_snackbar'.tr,
                                        ),
                                      ),
                                    );
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'face_section_title'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
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
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'face_section_description'.tr,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ListTile(
                      leading: Icon(
                        Icons.face,
                        color: _faceAvailable
                            ? (enabled ? cs.primary : cs.onSurfaceVariant)
                            : Colors.grey,
                        size: 28,
                      ),
                      title: Text('face_connection_title'.tr),
                      subtitle: Text(
                        !_faceAvailable
                            ? 'face_not_available_status'.tr
                            : enabled
                            ? 'face_enabled_status'.tr
                            : 'face_disabled_status'.tr,
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
                                      SnackBar(
                                        content: Text(
                                          'face_disabled_snackbar'.tr,
                                        ),
                                      ),
                                    );
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
                subtitle: Text('mlkit_download_test_subtitle'.tr),
                onTap: () => Navigator.pushNamed(context, '/mlkitDiag'),
              ),
            ],
          ),
        ),
        if (locationEnabled)
          const Expanded(child: SizedBox(height: 300, child: MapScreen())),
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
