import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/presentation/screens/face_capture_screen.dart';
import 'package:atelier7/utils/biometric_service.dart';
import 'package:atelier7/utils/form_validators.dart';

class Loginform extends StatefulWidget {
  const Loginform({super.key});

  @override
  State<Loginform> createState() => _Loginform();
}

class _Loginform extends State<Loginform> {
  final AuthController _controller = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isObscure = true;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  String? _biometricError;

  // Types biométriques disponibles
  bool _fingerprintAvailable = false;

  // ML Kit Face ID
  bool _isFaceIdMlKitLoading = false;
  String? _faceIdMlKitError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.checkBiometricAvailability();
      final bs = _controller.biometricService;
      final fp = await bs.isFingerprintAvailable();
      if (mounted) {
        setState(() {
          _fingerprintAvailable = fp;
          // Si aucun type détecté mais appareil disponible → activer empreinte par défaut
          if (!fp && _controller.isBiometricAvailable.value) {
            _fingerprintAvailable = true;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //Biometrics
  Future<void> _loginWithBiometrics() async {
    setState(() {
      _isBiometricLoading = true;
      _biometricError = null;
    });

    try {
      final result = await _controller.loginWithBiometrics();
      if (!mounted) return;

      if (result) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/Products', (route) => false);
        return;
      }

      final biometricResult = _controller.lastBiometricResult.value;
      if (biometricResult == BiometricResult.cancelled) return;

      String errorMessage;
      switch (biometricResult) {
        case BiometricResult.lockedOut:
          errorMessage =
              'Trop de tentatives. Déverrouillez via PIN ou redémarrez le téléphone.';
          break;
        case BiometricResult.permissionDenied:
          errorMessage =
              'Permission biométrique refusée. Activez-la dans les paramètres.';
          break;
        case BiometricResult.notAvailable:
          errorMessage = 'Biométrie non disponible sur cet appareil.';
          break;
        case BiometricResult.failure:
          errorMessage = 'Authentification échouée. Utilisez email/password.';
          break;
        default:
          errorMessage = 'Erreur biométrique. Utilisez email/password.';
      }

      setState(() {
        _biometricError = errorMessage;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _biometricError = 'Erreur biométrique. Utilisez email/password.',
        );
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  /// Authentification Face ID ML Kit : lance la capture du visage
  Future<void> _loginWithFaceIdMlKit() async {
    setState(() {
      _isFaceIdMlKitLoading = true;
      _faceIdMlKitError = null;
    });

    try {
      // Vérifier que Face ID ML Kit est activé
      if (!_controller.isFaceIdMlKitEnabled.value) {
        if (mounted) {
          setState(() {
            _faceIdMlKitError =
                'Face ID ML Kit n\'est pas activé. Activez-le dans les paramètres.';
          });
        }
        return;
      }

      // Lancer l'écran de capture pour la vérification
      if (!mounted) return;
      final verifyResult = await Navigator.of(
        context,
      ).pushNamed('/faceCapture', arguments: FaceCaptureMode.verify);

      if (!mounted) return;

      if (verifyResult == true) {
        // Visage reconnu - effectuer le login avec les credentials stockés
        final loginResult = await _controller.loginWithFaceIdMlKit();

        if (!mounted) return;

        if (loginResult) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/Products', (route) => false);
          return;
        } else {
          setState(() {
            _faceIdMlKitError = 'Login échoué. Vérifiez vos identifiants.';
          });
        }
      } else {
        // Utilisateur a annulé ou visage non reconnu
        setState(() {
          _faceIdMlKitError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _faceIdMlKitError = 'Erreur Face ID: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isFaceIdMlKitLoading = false);
    }
  }

  Widget _buildBiometricButton({
    required IconData icon,
    required String label,
    required bool available,
    required bool enabled,
    required bool canUse,
  }) {
    final Color borderColor;
    final String subtitle;

    if (!available) {
      borderColor = Colors.grey.shade400;
      subtitle = 'fingerprint_not_available'.tr;
    } else if (!enabled) {
      borderColor = Colors.orange;
      subtitle = 'fingerprint_disabled'.tr;
    } else {
      borderColor = Colors.purple;
      subtitle = 'press_to_login'.tr;
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: canUse && !_isBiometricLoading ? _loginWithBiometrics : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(color: borderColor),
          foregroundColor: borderColor,
          disabledForegroundColor: Colors.grey.shade400,
        ),
        child: _isBiometricLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: canUse ? Colors.purple : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: canUse ? Colors.purple : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'connexion'.tr,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('login_subtitle'.tr, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'email'.tr,
                labelText: 'email'.tr,
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: FormValidators.validateEmail,
            ),
            const SizedBox(height: 12),

            // Password
            TextFormField(
              obscureText: _isObscure,
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'password'.tr,
                labelText: 'password'.tr,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
              ),
              validator: FormValidators.validatePassword,
            ),
            const SizedBox(height: 20),

            // Bouton Se connecter
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        try {
                          setState(() => _isLoading = true);
                          final success = await _controller.login(
                            _emailController.text.trim(),
                            _passwordController.text,
                          );
                          if (!context.mounted) return;
                          if (success) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/Products',
                              (route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('invalid_credentials'.tr)),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${'erreur'.tr}: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'login_button'.tr,
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Séparateur
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'or'.tr,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 16),

            // ── Bouton empreinte + bouton Face ID ML Kit ───────────────────
            Obx(() {
              final enabled = _controller.isBiometricEnabled.value;
              final canUse = _controller.isBiometricAvailable.value && enabled;

              return Column(
                children: [
                  // Bouton Empreinte digitale
                  _buildBiometricButton(
                    icon: Icons.fingerprint,
                    label: 'fingerprint'.tr,
                    available: _fingerprintAvailable,
                    enabled: enabled,
                    canUse: canUse && _fingerprintAvailable,
                  ),
                  // Message d'erreur
                  if (_biometricError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _biometricError!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),

            const SizedBox(height: 16),

            // ── BOUTON FACE ID ML KIT ───────────────────────────────────────
            Obx(() {
              final mlkitEnabled = _controller.isFaceIdMlKitEnabled.value;
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: !mlkitEnabled || _isFaceIdMlKitLoading
                      ? null
                      : _loginWithFaceIdMlKit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    side: BorderSide(
                      color: mlkitEnabled
                          ? Colors.purple
                          : Colors.grey.shade400,
                    ),
                    foregroundColor: mlkitEnabled
                        ? Colors.purple
                        : Colors.grey.shade400,
                    disabledForegroundColor: Colors.grey.shade400,
                  ),
                  child: _isFaceIdMlKitLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          children: [
                            Icon(
                              Icons.face_retouching_natural,
                              size: 26,
                              color: mlkitEnabled
                                  ? Colors.purple
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'faceid_label'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: mlkitEnabled
                                        ? Colors.purple
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  mlkitEnabled
                                      ? 'use_registered_face'.tr
                                      : 'not_configured'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              );
            }),

            // Message d'erreur Face ID ML Kit
            if (_faceIdMlKitError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _faceIdMlKitError!,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text('no_account'.tr),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text(
                    'create_account'.tr,
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
