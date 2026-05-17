import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Documents extends StatelessWidget {
  const Documents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('documents'.tr)),
      body: Center(child: Text('documents_available_list'.tr)),
    );
  }
}
