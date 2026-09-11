import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_deck/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens URL import and validates placeholder flow', (
    tester,
  ) async {
    await tester.pumpWidget(const RecipeDeckApp());
    await tester.pumpAndSettle();

    expect(find.text('Recipe Deck'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openRecipeUrlImportButton')));
    await tester.pumpAndSettle();

    expect(find.text('Import Recipe URL'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('recipeUrlField')),
      'not a url',
    );
    await tester.tap(find.byKey(const Key('importRecipeUrlButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid http or https URL.'), findsOneWidget);

    const url = 'https://example.com/recipes/chili';
    await tester.enterText(find.byKey(const Key('recipeUrlField')), url);
    await tester.tap(find.byKey(const Key('importRecipeUrlButton')));
    await tester.pumpAndSettle();

    expect(find.text('Ready for import'), findsOneWidget);
    expect(find.text(url), findsOneWidget);
  });
}
