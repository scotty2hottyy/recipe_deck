import 'package:flutter/material.dart';

import 'screens/recipe_list_screen.dart';

void main() {
  runApp(const RecipeDeckApp());
}

class RecipeDeckApp extends StatelessWidget {
  const RecipeDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Deck',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const RecipeListScreen(),
    );
  }
}
