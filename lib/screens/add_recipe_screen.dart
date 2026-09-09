import 'package:flutter/material.dart';

class AddRecipeScreen extends StatelessWidget {
  const AddRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipe')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Add recipe form will go here.'),
      ),
    );
  }
}
