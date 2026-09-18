import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_deck/services/recipe_page_service.dart';
import 'package:recipe_deck/services/recipe_parser_service.dart';
import 'package:recipe_deck/services/recipe_text.dart';

void main() {
  test(
    'decodes entities and preserves quantities and notes in both parsers',
    () {
      final ingredients = [
        '50 &#8211; 100 g (¼ &#8211; 1/2 cup) bubbly, active starter – I always use 100 grams, see notes above',
        '375 g (1 1/2 cups plus 1 tbsp) warm water, or more, see notes above',
        '500 g (4 cups plus 2 tbsp) bread flour',
        '9 to 12 g (1.5 &#8211; 2.5 teaspoons) fine sea salt, see notes above',
      ];
      final expected = ingredients
          .map((s) => s.replaceAll('&#8211;', '–'))
          .toList();
      final html =
          '<script type="application/ld+json">${jsonEncode({
            '@type': 'Recipe',
            'name': 'Bread &amp; Butter',
            'recipeIngredient': ingredients,
            'recipeInstructions': ['<b>Mix</b>&nbsp; well &#x2014; then rest.'],
            'image': 'https://example.com/photo?a=1&b=2',
          })}</script>';
      final imported = RecipePageParser().parse(
        html,
        sourceUrl: 'https://example.com',
      );
      final parsed = RecipeParserService().parse(html);
      expect(imported!.ingredients, expected);
      expect(parsed!.ingredients, expected);
      expect(imported.title, 'Bread & Butter');
      expect(parsed.title, imported.title);
      expect(imported.instructions, ['Mix well — then rest.']);
      expect(parsed.instructions, imported.instructions);
      expect(imported.imageUrl, 'https://example.com/photo?a=1&b=2');
    },
  );

  test('HTML fallback does not interpret decoded text as markup again', () {
    final recipe = RecipeParserService().parse('''
      <h1>Example</h1>
      <p itemprop="recipeIngredient">Salt &amp; pepper &lt;optional&gt;</p>
      <p itemprop="recipeInstructions">Mix.</p>
    ''');
    expect(recipe!.ingredients, ['Salt & pepper <optional>']);
  });

  test('cleans layout whitespace and markup without losing recipe text', () {
    expect(
      cleanRecipeText(
        '<p>1&nbsp; cup <b>flour</b></p><p> sifted<br> gently</p>',
      ),
      '1 cup flour sifted gently',
    );
    expect(
      cleanRecipeText('¼–½ cup &amp; 1/3 cup; heat < 200°C'),
      '¼–½ cup & 1/3 cup; heat < 200°C',
    );
    expect(
      cleanRecipeText('<script>unwanted()</script><style>p{}</style>salt'),
      'salt',
    );
    expect(cleanRecipeText('&nbsp; <b> </b>'), '');
  });
}
