import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:recipe_deck/main.dart';
import 'package:recipe_deck/services/recipe_page_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens URL import and validates placeholder flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      RecipeDeckApp(
        recipePageService: RecipePageService(
          request: (_) async =>
              http.Response('<html>not structured</html>', 200),
        ),
      ),
    );
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
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == url,
      ),
      findsOneWidget,
    );
  });
}
