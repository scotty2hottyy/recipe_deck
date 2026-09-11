import 'package:flutter/material.dart';

import 'screens/recipe_list_screen.dart';
import 'services/recipe_database_service.dart';

void main() {
  runApp(const RecipeDeckApp());
}

class RecipeDeckApp extends StatelessWidget {
  const RecipeDeckApp({super.key, this.databaseService});

  final RecipeDatabaseService? databaseService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Deck',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: RecipeListScreen(databaseService: databaseService),
    );
  }
}
