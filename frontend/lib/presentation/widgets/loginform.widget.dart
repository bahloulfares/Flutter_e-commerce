import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
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

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.checkBiometricAvailability();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithBiometrics() async {
    setState(() {
      _isBiometricLoading = true;
      _biometricError = null;
    });

    try {
      final result = await _controller.loginWithBiometrics();
      if (!mounted) return;

      if (result) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/Products', (route) => false);
        return;
      }

      final biometricResult = _controller.lastBiometricResult.value;
      if (biometricResult == BiometricResult.cancelled) return;

      setState(() {
        _biometricError = biometricResult == BiometricResult.failure
            ? 'Trop de tentatives. Déverrouillez via PIN ou redémarrez le téléphone.'
            : 'Authentification échouée. Utilisez email/password.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _biometricError =
            'Erreur biométrique. Utilisez email/password.');
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Connexion',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Entrez vos informations pour continuer',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                labelText: 'Email',
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
                hintText: 'Password',
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off),
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
                                '/Products', (route) => false);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Email ou mot de passe invalide')),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Se connecter',
                        style: TextStyle(color: Colors.white)),
              ),
            ),

            const SizedBox(height: 16),

            // Séparateur
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('ou', style: TextStyle(color: Colors.grey[600])),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 16),

            // Bouton biométrique — TOUJOURS VISIBLE
            Obx(() {
              final deviceAvailable = _controller.isBiometricAvailable.value;
              final enabled = _controller.isBiometricEnabled.value;

              // État du bouton
              final canUse = deviceAvailable && enabled;
              final String label;
              final String subtitle;
              final Color borderColor;

              if (!deviceAvailable) {
                label = 'Biométrie non disponible';
                subtitle = 'Votre appareil ne supporte pas la biométrie';
                borderColor = Colors.grey;
              } else if (!enabled) {
                label = 'Biométrie désactivée';
                subtitle = 'Activez-la dans Paramètres → Biométrie';
                borderColor = Colors.orange;
              } else {
                label = 'Connexion biométrique';
                subtitle = 'Empreinte digitale ou Face ID';
                borderColor = Colors.purple;
              }

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: canUse && !_isBiometricLoading
                          ? _loginWithBiometrics
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: borderColor),
                        foregroundColor: borderColor,
                      ),
                      child: _isBiometricLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  deviceAvailable && enabled
                                      ? Icons.fingerprint
                                      : Icons.fingerprint,
                                  size: 28,
                                  color: canUse ? Colors.purple : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: canUse
                                                ? Colors.purple
                                                : Colors.grey)),
                                    Text(subtitle,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600])),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_biometricError != null) ...[
                    const SizedBox(height: 6),
                    Text(_biometricError!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              );
            }),

            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text("Vous n'avez pas de compte ? "),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Créer un compte',
                      style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
