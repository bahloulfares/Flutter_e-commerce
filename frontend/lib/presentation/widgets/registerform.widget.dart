import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/utils/form_validators.dart';

class Registerform extends StatefulWidget {
  const Registerform({super.key});

  @override
  State<Registerform> createState() => _Registerform();
}

class _Registerform extends State<Registerform> {
  // Initialisation du contrôleur
  final AuthController _controller = Get.put(AuthController(
    userUseCase: Get.find(),
  ));

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _passwordController2;

  // show the password or not
  bool _isObscure = true;
  bool _isObscure2 = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordController2 = TextEditingController();
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
          children: <Widget>[
            const SizedBox(height: 16),
            const Text(
              'Créer un compte',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inscrivez-vous pour accéder à toutes les fonctionnalités',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  icon: Icon(Icons.person), hintText: "Nom", labelText: "Nom"),
              validator: FormValidators.validateUsername,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                  icon: Icon(Icons.email_outlined),
                  hintText: "Email",
                  labelText: "Email"),
              validator: FormValidators.validateEmail,
            ),
            TextFormField(
              obscureText: _isObscure,
              controller: _passwordController,
              decoration: InputDecoration(
                icon: const Icon(Icons.key_rounded),
                hintText: "Password",
                labelText: "Password",
                // this button is used to toggle the password visibility
                suffixIcon: IconButton(
                    icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    }),
              ),
              validator: FormValidators.validatePassword,
            ),
            TextFormField(
              obscureText: _isObscure2,
              controller: _passwordController2,
              decoration: InputDecoration(
                icon: const Icon(Icons.key_outlined),
                hintText: "Retape Password",
                labelText: "Retape Password",
                // this button is used to toggle the password visibility
                suffixIcon: IconButton(
                    icon: Icon(
                        _isObscure2 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure2 = !_isObscure2;
                      });
                    }),
              ),
              validator: (value) {
                return FormValidators.validatePasswordConfirmation(
                  value,
                  _passwordController.text,
                );
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          developer.log(
                              'Register name: ${_nameController.text}',
                              name: 'Registerform');
                          developer.log(
                              'Register email: ${_emailController.text}',
                              name: 'Registerform');
                          developer.log(
                              'Register password length: ${_passwordController.text.length}',
                              name: 'Registerform');

                          try {
                            setState(() => _isLoading = true);
                            final success = await _controller.register(
                              _nameController.text,
                              _emailController.text,
                              _passwordController.text,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Compte créé avec succès')),
                              );
                              Navigator.of(context).pushNamed('/Settings');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Échec de création du compte')),
                              );
                            }
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error adding user: $error')),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    Colors.purpleAccent,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("S'inscrire"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
