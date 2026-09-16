import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/recipe_list_screen.dart';
import 'services/recipe_database_service.dart';
import 'services/recipe_page_service.dart';

void main() {
  // Widget build/layout errors show a plain message instead of the default
  // red error screen, so an unexpected UI error does not look like a crash.
  ErrorWidget.builder = (details) => const ColoredBox(
    color: Colors.white,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Something went wrong displaying this screen.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  runZonedGuarded(
    () {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('Unhandled Flutter error: ${details.exceptionAsString()}');
      };

      runApp(const RecipeDeckApp());
    },
    (error, stack) {
      // Catches errors outside the Flutter widget tree (e.g. async/database
      // failures) so they are logged instead of crashing the app silently.
      debugPrint('Unhandled error: $error');
    },
  );
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
