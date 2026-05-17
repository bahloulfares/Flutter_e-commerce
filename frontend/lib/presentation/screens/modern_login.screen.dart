import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/presentation/screens/face_capture_screen.dart';
import 'package:atelier7/utils/form_validators.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthController _controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late AnimationController _animationController;

  bool _isObscure = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isBiometricAvailable = false;
  late LocalAuthentication _localAuth;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _localAuth = LocalAuthentication();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;

      if (canAuthenticateWithBiometrics) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        setState(() {
          _isBiometricAvailable = availableBiometrics.isNotEmpty;
          _availableBiometrics = availableBiometrics;
        });
      }
    } catch (e) {
      debugPrint('Erreur vérification biométrie: $e');
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason:
            'Veuillez vous authentifier avec votre empreinte ou visage',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isAuthenticated && mounted) {
        setState(() => _isLoading = true);
        try {
          // Auto-login with stored credentials or use a biometric token
          final success = await _controller.loginWithBiometrics();

          if (!mounted) return;

          if (success) {
            Get.offAllNamed('/Products');
          } else {
            _showErrorSnackbar(
              'Authentification biométrique échouée. Veuillez utiliser email/mot de passe.',
            );
          }
        } catch (e) {
          if (mounted) {
            _showErrorSnackbar('Erreur: $e');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur biométrique: $e');
      }
    }
  }

  Future<void> _handleFaceIdMlKitLogin() async {
    try {
      final verifyResult = await Navigator.of(context).pushNamed(
        '/faceCapture',
        arguments: FaceCaptureMode.verify,
      );

      if (!mounted) return;

      if (verifyResult == true) {
        setState(() => _isLoading = true);
        try {
          final success = await _controller.loginWithFaceIdMlKit();

          if (!mounted) return;

          if (success) {
            Get.offAllNamed('/Products');
          } else {
            _showErrorSnackbar(
              'Face ID reconnu mais connexion impossible. Vérifiez vos identifiants enregistrés.',
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur Face ID ML Kit: $e');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _controller.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Get.offAllNamed('/Products');
      } else {
        _showErrorSnackbar('Email ou mot de passe incorrect');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur de connexion: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // Header avec animation
                  Expanded(
                    flex: 2,
                    child: FadeTransition(
                      opacity: Tween(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(_animationController),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo/Icône
                          ScaleTransition(
                            scale: Tween(begin: 0.5, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Curves.elasticOut,
                              ),
                            ),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Text(
                            'Bienvenue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Connectez-vous à votre compte',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Login Form
                  Expanded(
                    flex: 3,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 40,
                            bottom: 24,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email Field
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF667EEA),
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: 'exemple@email.com',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.mail_outline,
                                      color: Color(0xFF667EEA),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Color(0xFF667EEA),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: FormValidators.validateEmail,
                                  onChanged: (_) =>
                                      _formKey.currentState?.validate(),
                                ),
                                SizedBox(height: 24),
                                // Password Field
                                Text(
                                  'Mot de passe',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF667EEA),
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _isObscure,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF667EEA),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isObscure = !_isObscure;
                                        });
                                      },
                                      child: Icon(
                                        _isObscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Color(0xFF667EEA),
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Color(0xFF667EEA),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: FormValidators.validatePassword,
                                  onChanged: (_) =>
                                      _formKey.currentState?.validate(),
                                ),
                                SizedBox(height: 16),
                                // Remember Me & Forgot Password
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: Color(0xFF667EEA),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Se souvenir de moi',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Get.toNamed('/ResetPassword');
                                      },
                                      child: Text(
                                        'Mot de passe oublié?',
                                        style: TextStyle(
                                          color: Color(0xFF667EEA),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32),
                                // Biometric Login Button (if available)
                                if (_isBiometricAvailable) ...[
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Color(0xFF667EEA),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap:
                                            _isLoading ? null : _handleBiometricLogin,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _availableBiometrics.contains(
                                                      BiometricType.face,
                                                    )
                                                    ? Icons.face
                                                    : Icons.fingerprint,
                                                color: Color(0xFF667EEA),
                                                size: 24,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Connexion biométrique',
                                                style: TextStyle(
                                                  color: Color(0xFF667EEA),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                ],
                                Opacity(
                                  opacity: _isLoading ? 0.5 : 1.0,
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Color(0xFF667EEA),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading
                                            ? null
                                            : _handleFaceIdMlKitLogin,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.face,
                                                color: Color(0xFF667EEA),
                                                size: 20,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Se connecter avec Face ID ML Kit',
                                                style: TextStyle(
                                                  color: Color(0xFF667EEA),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                // Login Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(
                                          0xFF667EEA,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isLoading ? null : _handleLogin,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Center(
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                  strokeWidth: 3,
                                                ),
                                              )
                                            : Text(
                                                'SE CONNECTER',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'OU',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                // Social Login
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildSocialButton(
                                      icon: 'assets/icons/google.svg',
                                      onTap: () {},
                                    ),
                                    _buildSocialButton(
                                      icon: 'assets/icons/facebook.svg',
                                      onTap: () {},
                                    ),
                                    _buildSocialButton(
                                      icon: 'assets/icons/apple.svg',
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                // Sign Up Link
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Pas encore de compte? ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'S\'inscrire',
                                          style: TextStyle(
                                            color: Color(0xFF667EEA),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Get.toNamed('/Register');
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: Icon(Icons.g_translate, color: Color(0xFF667EEA), size: 24),
        ),
      ),
    );
  }
}
