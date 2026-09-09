import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipeTitle});

  final String recipeTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipeTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Recipe details will go here.'),
          ],
        ),
      ),
    );
  }
}
