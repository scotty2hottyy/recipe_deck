import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/recipe.dart';

class RecipeDatabaseService {
  RecipeDatabaseService({
    sqflite.DatabaseFactory? databaseFactory,
    this.databasePath,
  }) : _databaseFactory = databaseFactory ?? sqflite.databaseFactory;

  static const String _databaseName = 'recipe_deck.db';
  static const int _databaseVersion = 1;
  static const String _recipesTable = 'recipes';

  final sqflite.DatabaseFactory _databaseFactory;
  final String? databasePath;

  sqflite.Database? _database;

  Future<void> saveRecipe(Recipe recipe) async {
    final db = await _getDatabase();

    await db.insert(
      _recipesTable,
      _recipeToDatabaseMap(recipe),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<Recipe?> getRecipeById(String id) async {
    final db = await _getDatabase();

    final rows = await db.query(
      _recipesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _recipeFromDatabaseMap(rows.first);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await _getDatabase();
    final rows = await db.query(_recipesTable, orderBy: 'title ASC');

    return rows.map(_recipeFromDatabaseMap).toList();
  }

  Future<void> deleteRecipe(String id) async {
    final db = await _getDatabase();
    await db.delete(_recipesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<sqflite.Database> _getDatabase() async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath =
        this.databasePath ??
        path.join(await _databaseFactory.getDatabasesPath(), _databaseName);

    _database = await _databaseFactory.openDatabase(
      databasePath,
      options: sqflite.OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_recipesTable (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              ingredients TEXT NOT NULL,
              instructions TEXT NOT NULL,
              sourceUrl TEXT,
              imageUrl TEXT
            )
          ''');
        },
      ),
    );

    return _database!;
  }

  Map<String, Object?> _recipeToDatabaseMap(Recipe recipe) {
    return {
      'id': recipe.id,
      'title': recipe.title,
      'ingredients': jsonEncode(recipe.ingredients),
      'instructions': jsonEncode(recipe.instructions),
      'sourceUrl': recipe.sourceUrl,
      'imageUrl': recipe.imageUrl,
    };
  }

  Recipe _recipeFromDatabaseMap(Map<String, Object?> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      ingredients: List<String>.from(
        jsonDecode(map['ingredients'] as String) as List,
      ),
      instructions: List<String>.from(
        jsonDecode(map['instructions'] as String) as List,
      ),
      sourceUrl: map['sourceUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
