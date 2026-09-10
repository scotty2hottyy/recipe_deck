import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_deck/models/recipe.dart';

void main() {
  test('creates a recipe object and preserves required fields', () {
    const recipe = Recipe(
      id: 'recipe-1',
      title: 'Classic Pancakes',
      ingredients: ['Flour', 'Milk', 'Eggs'],
      instructions: ['Mix ingredients', 'Cook on a skillet'],
    );

    expect(recipe.id, 'recipe-1');
    expect(recipe.title, 'Classic Pancakes');
    expect(recipe.ingredients, ['Flour', 'Milk', 'Eggs']);
    expect(recipe.instructions, ['Mix ingredients', 'Cook on a skillet']);
  });

  test('optional URL fields default to null', () {
    const recipe = Recipe(
      id: 'recipe-2',
      title: 'Tomato Soup',
      ingredients: ['Tomatoes', 'Broth'],
      instructions: ['Simmer tomatoes', 'Blend soup'],
    );

    expect(recipe.sourceUrl, isNull);
    expect(recipe.imageUrl, isNull);
  });

  test('optional URL fields can be set', () {
    const recipe = Recipe(
      id: 'recipe-3',
      title: 'Veggie Pasta',
      ingredients: ['Pasta', 'Vegetables'],
      instructions: ['Boil pasta', 'Add vegetables'],
      sourceUrl: 'https://example.com/veggie-pasta',
      imageUrl: 'https://example.com/veggie-pasta.jpg',
    );

    expect(recipe.sourceUrl, 'https://example.com/veggie-pasta');
    expect(recipe.imageUrl, 'https://example.com/veggie-pasta.jpg');
  });

  test('toMap and fromMap preserve recipe data', () {
    const recipe = Recipe(
      id: 'recipe-4',
      title: 'Berry Smoothie',
      ingredients: ['Berries', 'Yogurt', 'Honey'],
      instructions: ['Add ingredients to blender', 'Blend until smooth'],
      sourceUrl: 'https://example.com/berry-smoothie',
      imageUrl: 'https://example.com/berry-smoothie.jpg',
    );

    final map = recipe.toMap();
    final restoredRecipe = Recipe.fromMap(map);

    expect(restoredRecipe.id, recipe.id);
    expect(restoredRecipe.title, recipe.title);
    expect(restoredRecipe.ingredients, recipe.ingredients);
    expect(restoredRecipe.instructions, recipe.instructions);
    expect(restoredRecipe.sourceUrl, recipe.sourceUrl);
    expect(restoredRecipe.imageUrl, recipe.imageUrl);
  });
}
