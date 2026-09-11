import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_deck/main.dart';
import 'package:recipe_deck/models/recipe.dart';
import 'package:recipe_deck/services/recipe_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MemoryRecipeDatabase extends RecipeDatabaseService {
  MemoryRecipeDatabase() : super(databaseFactory: databaseFactoryFfi);

  final recipes = <String, Recipe>{};
  bool failSave = false;
  bool failLoad = false;
  bool failDelete = false;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    if (failLoad) throw StateError('load failed');
    return recipes.values.toList()..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    if (failSave) throw StateError('save failed');
    recipes[recipe.id] = recipe;
  }

  @override
  Future<void> deleteRecipe(String id) async {
    if (failDelete) throw StateError('delete failed');
    recipes.remove(id);
  }
}

const sampleRecipe = Recipe(
  id: 'pancakes',
  title: 'Pancakes',
  ingredients: ['1 cup flour', '1 cup milk'],
  instructions: ['Mix batter', 'Cook until golden'],
  sourceUrl: 'https://example.com/pancakes',
  imageUrl: 'https://example.com/pancakes.jpg',
);

Future<void> saveForm(WidgetTester tester) async {
  final save = find.byKey(const Key('saveRecipeButton'));
  await tester.scrollUntilVisible(
    save,
    250,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('manual entry validates, trims lines, saves and opens detail', (
    tester,
  ) async {
    final database = MemoryRecipeDatabase();
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();
    expect(find.text('Your recipe deck starts here'), findsOneWidget);
    expect(find.text('Classic Pancakes'), findsNothing);
    await tester.tap(find.byKey(const Key('addRecipeButton')));
    await tester.pumpAndSettle();
    await saveForm(tester);
    expect(database.recipes, isEmpty);
    expect(find.text('Enter at least one instruction.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('recipeTitleField')),
      '  Pancakes  ',
    );
    await tester.enterText(
      find.byKey(const Key('recipeIngredientsField')),
      ' 1 cup flour\n\n 1 cup milk ',
    );
    await tester.enterText(
      find.byKey(const Key('recipeInstructionsField')),
      ' Mix batter\n\nCook until golden ',
    );
    await saveForm(tester);
    expect(database.recipes, hasLength(1));
    final saved = database.recipes.values.single;
    expect(saved.title, 'Pancakes');
    expect(saved.ingredients, sampleRecipe.ingredients);
    expect(saved.instructions, sampleRecipe.instructions);
    await tester.tap(find.text('Pancakes'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('1 cup flour'), findsOneWidget);
    expect(find.text('Mix batter'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Pancakes'), findsOneWidget);
  });

  testWidgets(
    'editing preserves identity and metadata and refreshes detail/list',
    (tester) async {
      final database = MemoryRecipeDatabase()
        ..recipes[sampleRecipe.id] = sampleRecipe;
      await tester.pumpWidget(RecipeDeckApp(databaseService: database));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pancakes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit Recipe'));
      await tester.pumpAndSettle();
      expect(find.text('1 cup flour\n1 cup milk'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('recipeTitleField')),
        'Weekend Pancakes',
      );
      await tester.enterText(
        find.byKey(const Key('recipeInstructionsField')),
        'Whisk\nCook\nServe',
      );
      await saveForm(tester);
      expect(find.text('Weekend Pancakes'), findsOneWidget);
      expect(find.text('Whisk'), findsOneWidget);
      expect(database.recipes, hasLength(1));
      expect(
        database.recipes[sampleRecipe.id]!.sourceUrl,
        sampleRecipe.sourceUrl,
      );
      expect(
        database.recipes[sampleRecipe.id]!.imageUrl,
        sampleRecipe.imageUrl,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Weekend Pancakes'), findsOneWidget);
      expect(find.text('Pancakes'), findsNothing);
    },
  );

  testWidgets('delete cancel preserves recipe, confirm removes it', (
    tester,
  ) async {
    final database = MemoryRecipeDatabase()
      ..recipes[sampleRecipe.id] = sampleRecipe;
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pancakes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(database.recipes, hasLength(1));
    await tester.tap(find.byTooltip('Delete Recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(database.recipes, isEmpty);
    expect(find.text('Your recipe deck starts here'), findsOneWidget);
  });

  testWidgets('load failure retries and save failure retains form for retry', (
    tester,
  ) async {
    final database = MemoryRecipeDatabase()..failLoad = true;
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();
    expect(find.text('Could not load your recipes.'), findsOneWidget);
    database.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addRecipeButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('recipeTitleField')), 'Soup');
    await tester.enterText(
      find.byKey(const Key('recipeIngredientsField')),
      'Tomatoes',
    );
    await tester.enterText(
      find.byKey(const Key('recipeInstructionsField')),
      'Simmer',
    );
    database.failSave = true;
    await saveForm(tester);
    expect(
      find.text('Could not save your recipe. Please try again.'),
      findsOneWidget,
    );
    expect(database.recipes, isEmpty);
    database.failSave = false;
    await saveForm(tester);
    expect(find.text('Soup'), findsOneWidget);
    expect(database.recipes, hasLength(1));
  });

  testWidgets('failed deletion keeps detail and saved recipe', (tester) async {
    final database = MemoryRecipeDatabase()
      ..recipes[sampleRecipe.id] = sampleRecipe
      ..failDelete = true;
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pancakes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(database.recipes, hasLength(1));
    expect(find.text('Recipe Detail'), findsOneWidget);
    expect(
      find.text('Could not delete the recipe. Please try again.'),
      findsOneWidget,
    );
  });
}
