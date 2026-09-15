import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:recipe_deck/services/recipe_page_service.dart';

void main() {
  test('retrieves the page body for a valid recipe URL', () async {
    final service = RecipePageService(
      request: (uri) async => http.Response('<html>recipe page</html>', 200),
    );

    final pageText = await service.fetch(
      Uri.parse('https://example.com/recipes/pancakes'),
    );

    expect(pageText, '<html>recipe page</html>');
  });

  test('turns a network failure into a safe fetch exception', () async {
    final service = RecipePageService(
      request: (_) async {
        throw http.ClientException('offline');
      },
    );

    expect(
      () => service.fetch(Uri.parse('https://example.com/recipes/pancakes')),
      throwsA(isA<RecipePageFetchException>()),
    );
  });

  test('passes downloaded HTML into the recipe parser', () async {
    const pageText = '''
      <html>
        <head>
          <script type="application/ld+json">
            {
              "@type": "Recipe",
              "name": "Test Pancakes",
              "recipeIngredient": ["1 cup flour", "1 egg"],
              "recipeInstructions": [
                {"@type": "HowToStep", "text": "Mix everything"},
                {"@type": "HowToStep", "text": "Cook the batter"}
              ],
              "image": "https://example.com/pancakes.jpg"
            }
          </script>
        </head>
      </html>
    ''';
    final service = RecipePageService(
      request: (_) async => http.Response(pageText, 200),
    );
    final parser = RecipePageParser();

    final downloadedPage = await service.fetch(
      Uri.parse('https://example.com/recipes/pancakes'),
    );
    final recipe = parser.parse(
      downloadedPage,
      sourceUrl: 'https://example.com/recipes/pancakes',
    );

    expect(recipe, isNotNull);
    expect(recipe!.title, 'Test Pancakes');
    expect(recipe.ingredients, ['1 cup flour', '1 egg']);
    expect(recipe.instructions, ['Mix everything', 'Cook the batter']);
    expect(recipe.sourceUrl, 'https://example.com/recipes/pancakes');
  });
}
