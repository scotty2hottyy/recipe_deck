import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:recipe_deck/models/recipe.dart';
import 'package:recipe_deck/services/recipe_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late String databasePath;
  late RecipeDatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'recipe_deck_database_test_',
    );
    databasePath = path.join(tempDirectory.path, 'recipe_deck_test.db');
    databaseService = RecipeDatabaseService(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await databaseService.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('saves a recipe and reads it back by id', () async {
    const recipe = Recipe(
      id: 'recipe-1',
      title: 'Classic Pancakes',
      ingredients: ['Flour', 'Milk', 'Eggs'],
      instructions: ['Mix batter', 'Cook on skillet'],
      sourceUrl: 'https://example.com/pancakes',
      imageUrl: 'https://example.com/pancakes.jpg',
    );

    await databaseService.saveRecipe(recipe);

    final savedRecipe = await databaseService.getRecipeById(recipe.id);

    expect(savedRecipe, isNotNull);
    expect(savedRecipe!.id, recipe.id);
    expect(savedRecipe.title, recipe.title);
    expect(savedRecipe.ingredients, recipe.ingredients);
    expect(savedRecipe.instructions, recipe.instructions);
    expect(savedRecipe.sourceUrl, recipe.sourceUrl);
    expect(savedRecipe.imageUrl, recipe.imageUrl);
  });

  test('returns all saved recipes', () async {
    const pancakes = Recipe(
      id: 'recipe-1',
      title: 'Classic Pancakes',
      ingredients: ['Flour', 'Milk'],
      instructions: ['Mix', 'Cook'],
    );
    const soup = Recipe(
      id: 'recipe-2',
      title: 'Tomato Soup',
      ingredients: ['Tomatoes', 'Broth'],
      instructions: ['Simmer', 'Blend'],
    );

    await databaseService.saveRecipe(soup);
    await databaseService.saveRecipe(pancakes);

    final recipes = await databaseService.getAllRecipes();

    expect(recipes, hasLength(2));
    expect(recipes.map((recipe) => recipe.id), ['recipe-1', 'recipe-2']);
  });

  test(
    'saved recipe remains after closing and reopening the database',
    () async {
      const recipe = Recipe(
        id: 'recipe-3',
        title: 'Berry Smoothie',
        ingredients: ['Berries', 'Yogurt', 'Honey'],
        instructions: ['Add ingredients', 'Blend until smooth'],
        sourceUrl: 'https://example.com/smoothie',
        imageUrl: 'https://example.com/smoothie.jpg',
      );

      await databaseService.saveRecipe(recipe);
      await databaseService.close();

      final reopenedDatabaseService = RecipeDatabaseService(
        databaseFactory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(reopenedDatabaseService.close);

      final savedRecipe = await reopenedDatabaseService.getRecipeById(
        recipe.id,
      );

      expect(savedRecipe, isNotNull);
      expect(savedRecipe!.title, recipe.title);
      expect(savedRecipe.ingredients, recipe.ingredients);
      expect(savedRecipe.instructions, recipe.instructions);
      expect(savedRecipe.sourceUrl, recipe.sourceUrl);
      expect(savedRecipe.imageUrl, recipe.imageUrl);
    },
  );
  test(
    'editing replaces only the selected recipe and survives reopening',
    () async {
      const original = Recipe(
        id: 'edit',
        title: 'Before',
        ingredients: ['Flour'],
        instructions: ['Mix'],
      );
      const other = Recipe(
        id: 'other',
        title: 'Other',
        ingredients: ['Water'],
        instructions: ['Boil'],
      );
      const updated = Recipe(
        id: 'edit',
        title: 'After',
        ingredients: ['Milk', 'Flour'],
        instructions: ['Whisk', 'Cook'],
      );
      await databaseService.saveRecipe(original);
      await databaseService.saveRecipe(other);
      await databaseService.saveRecipe(updated);
      await databaseService.close();
      expect((await databaseService.getAllRecipes()), hasLength(2));
      expect(
        (await databaseService.getRecipeById('edit'))!.toMap(),
        updated.toMap(),
      );
      expect(
        (await databaseService.getRecipeById('other'))!.toMap(),
        other.toMap(),
      );
    },
  );

  test('deletion survives reopening and leaves other recipes intact', () async {
    const removed = Recipe(
      id: "delete' OR 1=1 --",
      title: 'Removed',
      ingredients: ['Flour'],
      instructions: ['Mix'],
    );
    const kept = Recipe(
      id: 'kept',
      title: 'Kept',
      ingredients: ['Water'],
      instructions: ['Boil'],
    );
    await databaseService.saveRecipe(removed);
    await databaseService.saveRecipe(kept);
    await databaseService.deleteRecipe(removed.id);
    await databaseService.close();
    expect(await databaseService.getRecipeById(removed.id), isNull);
    expect((await databaseService.getAllRecipes()).map((r) => r.id), ['kept']);
  });
}
