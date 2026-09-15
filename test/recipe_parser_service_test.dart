import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_deck/services/recipe_parser_service.dart';

void main() {
  late RecipeParserService parser;

  setUp(() {
    parser = RecipeParserService();
  });

  test('parses normal JSON-LD Recipe title, ingredients, instructions', () {
    final recipe = parser.parse(
      _jsonLdHtml({
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'name': ' Tomato Soup ',
        'image': {
          '@type': 'ImageObject',
          'url': 'https://example.com/soup.jpg',
        },
        'recipeIngredient': [' Tomatoes ', '', 'Vegetable stock'],
        'recipeInstructions': [' Simmer the soup ', 'Serve warm'],
      }),
    );

    expect(recipe, isNotNull);
    expect(recipe!.title, 'Tomato Soup');
    expect(recipe.ingredients, ['Tomatoes', 'Vegetable stock']);
    expect(recipe.instructions, ['Simmer the soup', 'Serve warm']);
    expect(recipe.imageUrl, 'https://example.com/soup.jpg');
  });

  test('parses Recipe inside @graph', () {
    final recipe = parser.parse(
      _jsonLdHtml({
        '@context': 'https://schema.org',
        '@graph': [
          {'@type': 'WebPage', 'name': 'Not the recipe'},
          {
            '@type': ['Thing', 'Recipe'],
            'name': 'Graph Chili',
            'image': [
              'not a url',
              {'contentUrl': 'https://example.com/chili.jpg'},
            ],
            'recipeIngredient': ['Beans', 'Chiles'],
            'recipeInstructions': 'Cook until thick.',
          },
        ],
      }),
    );

    expect(recipe, isNotNull);
    expect(recipe!.title, 'Graph Chili');
    expect(recipe.ingredients, ['Beans', 'Chiles']);
    expect(recipe.instructions, ['Cook until thick.']);
    expect(recipe.imageUrl, 'https://example.com/chili.jpg');
  });

  test('parses HowToStep instructions', () {
    final recipe = parser.parse(
      _jsonLdHtml({
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'name': 'Skillet Cornbread',
        'recipeIngredient': ['Cornmeal'],
        'recipeInstructions': [
          {'@type': 'HowToStep', 'text': 'Heat the skillet.'},
          {'@type': 'HowToStep', 'text': 'Bake until golden.'},
        ],
      }),
    );

    expect(recipe, isNotNull);
    expect(recipe!.instructions, ['Heat the skillet.', 'Bake until golden.']);
  });

  test('parses HowToSection and nested instructions', () {
    final recipe = parser.parse(
      _jsonLdHtml({
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'name': 'Vegetable Stew',
        'recipeIngredient': ['Carrots'],
        'recipeInstructions': [
          {
            '@type': 'HowToSection',
            'name': 'Prep',
            'itemListElement': [
              {'@type': 'HowToStep', 'text': 'Chop the vegetables.'},
              {
                '@type': 'HowToSection',
                'name': 'Cook',
                'itemListElement': [
                  {'@type': 'HowToStep', 'text': 'Warm the pot.'},
                  {'@type': 'HowToStep', 'text': 'Simmer until tender.'},
                ],
              },
            ],
          },
        ],
      }),
    );

    expect(recipe, isNotNull);
    expect(recipe!.instructions, [
      'Chop the vegetables.',
      'Warm the pot.',
      'Simmer until tender.',
    ]);
  });

  test('handles missing title safely', () {
    final recipe = parser.parse(
      _jsonLdHtml({
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'recipeIngredient': ['Flour'],
        'recipeInstructions': ['Mix the batter.'],
      }),
    );

    expect(recipe, isNotNull);
    expect(recipe!.title, isNull);
    expect(recipe.ingredients, ['Flour']);
    expect(recipe.instructions, ['Mix the batter.']);
  });

  test('handles missing ingredients safely', () {
    final recipe = parser.parse(
      _jsonLdHtml({
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'name': 'No Ingredient Recipe',
        'recipeInstructions': ['Do the thing.'],
      }),
    );

    expect(recipe, isNotNull);
    expect(recipe!.title, 'No Ingredient Recipe');
    expect(recipe.ingredients, isEmpty);
    expect(recipe.instructions, ['Do the thing.']);
  });

  test('handles missing instructions safely', () {
    final recipe = parser.parse(
      _jsonLdHtml({
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'name': 'No Instruction Recipe',
        'recipeIngredient': ['Water'],
      }),
    );

    expect(recipe, isNotNull);
    expect(recipe!.title, 'No Instruction Recipe');
    expect(recipe.ingredients, ['Water']);
    expect(recipe.instructions, isEmpty);
  });

  test('ignores malformed JSON-LD without crashing', () {
    final recipe = parser.parse('''
      <!doctype html>
      <html>
        <head>
          <script type="application/ld+json">{ not valid json }</script>
          <script type="application/ld+json">
            ${jsonEncode([
      {
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'name': 'Second Script Recipe',
        'recipeIngredient': ['Oats'],
        'recipeInstructions': ['Toast the oats.'],
      },
    ])}
          </script>
        </head>
      </html>
    ''');

    expect(recipe, isNotNull);
    expect(recipe!.title, 'Second Script Recipe');
    expect(recipe.ingredients, ['Oats']);
    expect(recipe.instructions, ['Toast the oats.']);
  });

  test('unsupported non-recipe page returns null', () {
    final recipe = parser.parse('''
      <!doctype html>
      <html>
        <head><title>About Our Kitchen</title></head>
        <body>
          <h1>About Our Kitchen</h1>
          <p>This page has no recipe metadata.</p>
        </body>
      </html>
    ''');

    expect(recipe, isNull);
  });

  test('HTML itemprop fallback works when JSON-LD Recipe is absent', () {
    final recipe = parser.parse('''
      <!doctype html>
      <html>
        <head><title>Document Title</title></head>
        <body>
          <article itemscope itemtype="https://schema.org/Recipe">
            <h1 itemprop="name"> Fallback Stew </h1>
            <ul>
              <li itemprop="recipeIngredient"> Beans </li>
              <li itemprop="recipeIngredient"> Vegetable stock </li>
            </ul>
            <section itemprop="recipeInstructions">
              <ol>
                <li>Soak the beans.</li>
                <li>Simmer until tender.</li>
              </ol>
            </section>
            <img itemprop="image" src="https://example.com/stew.jpg">
          </article>
        </body>
      </html>
    ''');

    expect(recipe, isNotNull);
    expect(recipe!.title, 'Fallback Stew');
    expect(recipe.ingredients, ['Beans', 'Vegetable stock']);
    expect(recipe.instructions, ['Soak the beans.', 'Simmer until tender.']);
    expect(recipe.imageUrl, 'https://example.com/stew.jpg');
  });

  test('JSON-LD takes priority over fallback data when both exist', () {
    final recipe = parser.parse('''
      <!doctype html>
      <html>
        <head>
          <script type="application/ld+json">
            ${jsonEncode({
      '@context': 'https://schema.org',
      '@type': 'Recipe',
      'name': 'Structured Recipe',
      'image': 'https://example.com/structured.jpg',
      'recipeIngredient': ['Structured ingredient'],
      'recipeInstructions': ['Structured step'],
    })}
          </script>
        </head>
        <body>
          <h1 itemprop="name">Fallback Recipe</h1>
          <p itemprop="recipeIngredient">Fallback ingredient</p>
          <p itemprop="recipeInstructions">Fallback step</p>
        </body>
      </html>
    ''');

    expect(recipe, isNotNull);
    expect(recipe!.title, 'Structured Recipe');
    expect(recipe.ingredients, ['Structured ingredient']);
    expect(recipe.instructions, ['Structured step']);
    expect(recipe.imageUrl, 'https://example.com/structured.jpg');
  });
}

String _jsonLdHtml(Object jsonLd) {
  return '''
    <!doctype html>
    <html>
      <head>
        <script type="application/ld+json">
          ${jsonEncode(jsonLd)}
        </script>
      </head>
    </html>
  ''';
}
