import 'package:flutter/material.dart';
import 'package:atelier7/presentation/widgets/addcategorieform.widget.dart';

class Addcategorie extends StatelessWidget {
  const Addcategorie({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 15,
        backgroundColor: Colors.blueAccent,
        title: const Text("Add Categories"),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: const Addcategorieform(),
    );
  }
}
