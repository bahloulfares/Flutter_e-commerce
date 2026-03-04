import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class Subscribe extends StatefulWidget {
  const Subscribe({super.key});

  @override
  State<Subscribe> createState() => _SubscribeState();
}

class _SubscribeState extends State<Subscribe> {
  final _formKey = GlobalKey<FormState>();
  String? ville = 'Sfax';
  var items = ['Sfax', 'Tunis', 'Sousse', 'Gabes'];

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;

  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              icon: Icon(Icons.person),
              hintText: "Enter your Name",
              labelText: "Name",
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),

          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              icon: Icon(Icons.email),
              hintText: "Enter your Email",
              labelText: "Email",
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your Email';
              }
              return null;
            },
          ),

          // Password Field
          TextFormField(
            obscureText: _isObscure,
            controller: _passwordController,
            decoration: InputDecoration(
              icon: const Icon(Icons.key),
              hintText: "Enter your password",
              labelText: "Password",
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              icon: Icon(Icons.phone),
              hintText: "Enter your phone",
              labelText: "Phone",
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your phone';
              }
              return null;
            },
          ),

          // Dropdown Field
          DropdownButton(
            value: ville,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: items.map((items) {
              return DropdownMenuItem(value: items, child: Text(items));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                ville = newValue;
              });
            },
          ),

          // Submit Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  developer.log('Name: ${_nameController.text}',
                      name: 'Subscribe');
                  developer.log('Email: ${_emailController.text}',
                      name: 'Subscribe');
                  developer.log(
                      'Password length: ${_passwordController.text.length}',
                      name: 'Subscribe');
                  developer.log('Phone: ${_phoneController.text}',
                      name: 'Subscribe');
                  developer.log('Ville: $ville', name: 'Subscribe');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processing Data')),
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  Colors.greenAccent,
                ),
              ),
              child: const Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }
}
