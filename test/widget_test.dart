import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:recipe_deck/main.dart';
import 'package:recipe_deck/models/recipe.dart';
import 'package:recipe_deck/services/recipe_database_service.dart';
import 'package:recipe_deck/services/recipe_page_service.dart';
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
    500,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> openUrlImport(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openRecipeUrlImportButton')));
  await tester.pumpAndSettle();
  expect(find.text('Import Recipe URL'), findsOneWidget);
}

void main() {
  testWidgets('saved recipes filter by title and restore when cleared', (
    tester,
  ) async {
    final database = MemoryRecipeDatabase()
      ..recipes[sampleRecipe.id] = sampleRecipe
      ..recipes['chili'] = const Recipe(
        id: 'chili',
        title: 'Weeknight Chili',
        ingredients: ['Beans'],
        instructions: ['Simmer'],
      );
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();

    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('Weeknight Chili'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('recipeSearchField')), 'CHILI');
    await tester.pump();

    expect(find.text('Weeknight Chili'), findsOneWidget);
    expect(find.text('Pancakes'), findsNothing);

    await tester.tap(find.byKey(const Key('clearRecipeSearchButton')));
    await tester.pump();

    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('Weeknight Chili'), findsOneWidget);
  });

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

  testWidgets('recipe URL import accepts typed URL text', (tester) async {
    final database = MemoryRecipeDatabase();
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();
    await openUrlImport(tester);

    const url = 'https://example.com/recipes/chili';
    await tester.enterText(find.byKey(const Key('recipeUrlField')), url);

    expect(find.text(url), findsOneWidget);
  });

  testWidgets('add recipe imports a URL into the form before saving', (
    tester,
  ) async {
    const pageText = '''
      <script type="application/ld+json">
        {
          "@type": "Recipe",
          "name": "Imported Chili",
          "recipeIngredient": ["Beans", "Tomatoes"],
          "recipeInstructions": ["Mix ingredients", "Simmer"]
        }
      </script>
    ''';
    final database = MemoryRecipeDatabase();
    await tester.pumpWidget(
      RecipeDeckApp(
        databaseService: database,
        recipePageService: RecipePageService(
          request: (_) async => http.Response(pageText, 200),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addRecipeButton')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('importRecipeOnAddScreenButton')),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('importRecipeOnAddScreenButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recipeUrlField')),
      'https://example.com/recipes/chili',
    );
    await tester.tap(find.byKey(const Key('importRecipeUrlButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('useImportedRecipeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Imported Chili'), findsOneWidget);
    expect(find.text('Beans\nTomatoes'), findsOneWidget);
    expect(find.text('Mix ingredients\nSimmer'), findsOneWidget);

    expect(database.recipes, isEmpty);
  });

  testWidgets('recipe URL import rejects empty input', (tester) async {
    final database = MemoryRecipeDatabase();
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();
    await openUrlImport(tester);

    await tester.tap(find.byKey(const Key('importRecipeUrlButton')));
    await tester.pump();

    expect(find.text('Enter a recipe URL.'), findsOneWidget);
    expect(find.text('Ready for import'), findsNothing);
  });

  testWidgets('recipe URL import rejects invalid URLs', (tester) async {
    final database = MemoryRecipeDatabase();
    await tester.pumpWidget(RecipeDeckApp(databaseService: database));
    await tester.pumpAndSettle();
    await openUrlImport(tester);

    await tester.enterText(
      find.byKey(const Key('recipeUrlField')),
      'not a url',
    );
    await tester.tap(find.byKey(const Key('importRecipeUrlButton')));
    await tester.pump();

    expect(find.text('Enter a valid http or https URL.'), findsOneWidget);
    expect(find.text('Ready for import'), findsNothing);
  });

  testWidgets('recipe URL import retrieves a valid URL page', (tester) async {
    final database = MemoryRecipeDatabase();
    await tester.pumpWidget(
      RecipeDeckApp(
        databaseService: database,
        recipePageService: RecipePageService(
          request: (_) async => http.Response('<html>recipe page</html>', 200),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openUrlImport(tester);

    const url = 'https://example.com/recipes/chili';
    await tester.enterText(find.byKey(const Key('recipeUrlField')), ' $url ');
    await tester.tap(find.byKey(const Key('importRecipeUrlButton')));
    await tester.pumpAndSettle();

    expect(find.text('Ready for import'), findsOneWidget);
    expect(find.text(url), findsOneWidget);
    expect(find.text('Recipe page retrieved successfully.'), findsOneWidget);
    expect(
      find.text('The page was retrieved, but no structured recipe was found.'),
      findsOneWidget,
    );
    expect(database.recipes, isEmpty);
  });

  testWidgets('recipe URL import shows a network error without crashing', (
    tester,
  ) async {
    final database = MemoryRecipeDatabase();
    await tester.pumpWidget(
      RecipeDeckApp(
        databaseService: database,
        recipePageService: RecipePageService(
          request: (_) async => throw Exception('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openUrlImport(tester);

    await tester.enterText(
      find.byKey(const Key('recipeUrlField')),
      'https://example.com/recipes/chili',
    );
    await tester.tap(find.byKey(const Key('importRecipeUrlButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recipeImportError')), findsOneWidget);
    expect(find.textContaining('could not be reached'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
