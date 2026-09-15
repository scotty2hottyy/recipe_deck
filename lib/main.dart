import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/recipe_list_screen.dart';
import 'services/recipe_database_service.dart';
import 'services/recipe_page_service.dart';

void main() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const RecipeDeckApp());
}

class RecipeDeckApp extends StatelessWidget {
  const RecipeDeckApp({
    super.key,
    this.databaseService,
    this.recipePageService,
  });

  final RecipeDatabaseService? databaseService;
  final RecipePageService? recipePageService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Deck',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: RecipeListScreen(
        databaseService: databaseService,
        recipePageService: recipePageService,
      ),
    );
  }
}
