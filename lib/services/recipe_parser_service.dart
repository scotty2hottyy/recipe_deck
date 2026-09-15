import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class ParsedRecipeData {
  const ParsedRecipeData({
    this.title,
    this.ingredients = const <String>[],
    this.instructions = const <String>[],
    this.imageUrl,
  });

  final String? title;
  final List<String> ingredients;
  final List<String> instructions;
  final String? imageUrl;
}

class RecipeParserService {
  ParsedRecipeData? parse(String webpageHtml) {
    final document = html_parser.parse(webpageHtml);

    return _parseJsonLd(document) ?? _parseHtmlFallback(document);
  }

  ParsedRecipeData? _parseJsonLd(Document document) {
    for (final script in _jsonLdScripts(document)) {
      final scriptText = script.text.trim();
      if (scriptText.isEmpty) continue;

      final decoded = _decodeJsonSafely(scriptText);
      if (decoded == null) continue;

      for (final recipe in _findRecipeObjects(decoded)) {
        final parsedRecipe = _parseRecipeObject(recipe);
        if (_hasUsableRecipeData(parsedRecipe)) {
          return parsedRecipe;
        }
      }
    }

    return null;
  }

  ParsedRecipeData? _parseHtmlFallback(Document document) {
    final ingredients = _itemPropText(document, 'recipeIngredient');
    final instructions = _itemPropText(document, 'recipeInstructions');

    if (ingredients.isEmpty && instructions.isEmpty) {
      return null;
    }

    return ParsedRecipeData(
      title: _fallbackTitle(document),
      ingredients: ingredients,
      instructions: instructions,
      imageUrl: _fallbackImageUrl(document),
    );
  }

  Iterable<Element> _jsonLdScripts(Document document) {
    return document.querySelectorAll('script').where((script) {
      final type = script.attributes['type'];
      if (type == null) return false;

      final mediaType = type.split(';').first.trim().toLowerCase();
      return mediaType == 'application/ld+json';
    });
  }

  Object? _decodeJsonSafely(String jsonText) {
    try {
      return jsonDecode(jsonText);
    } on FormatException {
      return null;
    }
  }

  Iterable<Map<dynamic, dynamic>> _findRecipeObjects(Object? value) sync* {
    if (value is List) {
      for (final item in value) {
        yield* _findRecipeObjects(item);
      }
      return;
    }

    if (value is Map) {
      if (_isRecipeType(value['@type'])) {
        yield value;
        return;
      }

      for (final child in value.values) {
        yield* _findRecipeObjects(child);
      }
    }
  }

  ParsedRecipeData _parseRecipeObject(Map<dynamic, dynamic> recipe) {
    return ParsedRecipeData(
      title: _firstText(recipe['name']),
      ingredients: _textList(recipe['recipeIngredient']),
      instructions: _instructionList(recipe['recipeInstructions']),
      imageUrl: _imageUrl(recipe['image']),
    );
  }

  bool _hasUsableRecipeData(ParsedRecipeData recipe) {
    return recipe.title != null ||
        recipe.ingredients.isNotEmpty ||
        recipe.instructions.isNotEmpty ||
        recipe.imageUrl != null;
  }

  bool _isRecipeType(Object? value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'recipe' ||
          normalized.endsWith('/recipe') ||
          normalized.endsWith('#recipe');
    }

    if (value is List) {
      return value.any(_isRecipeType);
    }

    return false;
  }

  String? _firstText(Object? value) {
    final values = _textList(value);
    if (values.isEmpty) return null;
    return values.first;
  }

  List<String> _textList(Object? value) {
    final values = <String>[];

    void addValue(Object? candidate) {
      if (candidate == null) return;

      if (candidate is String) {
        values.addAll(_cleanTextEntries(candidate));
        return;
      }

      if (candidate is num || candidate is bool) {
        values.addAll(_cleanTextEntries(candidate.toString()));
        return;
      }

      if (candidate is List) {
        for (final item in candidate) {
          addValue(item);
        }
        return;
      }

      if (candidate is Map) {
        for (final key in const ['text', 'name', 'value']) {
          if (candidate.containsKey(key)) {
            addValue(candidate[key]);
            return;
          }
        }
      }
    }

    addValue(value);
    return values;
  }

  List<String> _instructionList(Object? value) {
    final instructions = <String>[];

    void addInstruction(Object? candidate) {
      if (candidate == null) return;

      if (candidate is String) {
        instructions.addAll(_cleanTextEntries(candidate));
        return;
      }

      if (candidate is List) {
        for (final item in candidate) {
          addInstruction(item);
        }
        return;
      }

      if (candidate is Map) {
        final itemListElement = candidate['itemListElement'];
        if (itemListElement != null) {
          addInstruction(itemListElement);
          return;
        }

        final text = candidate['text'];
        if (text != null) {
          addInstruction(text);
          return;
        }

        final item = candidate['item'];
        if (item != null) {
          addInstruction(item);
          return;
        }

        final name = candidate['name'];
        if (_isHowToStepType(candidate['@type']) && name != null) {
          addInstruction(name);
        }
      }
    }

    addInstruction(value);
    return instructions;
  }

  bool _isHowToStepType(Object? value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'howtostep' ||
          normalized.endsWith('/howtostep') ||
          normalized.endsWith('#howtostep');
    }

    if (value is List) {
      return value.any(_isHowToStepType);
    }

    return false;
  }

  List<String> _cleanTextEntries(String value) {
    return value
        .split(RegExp(r'[\r\n]+'))
        .map(_cleanText)
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  String _cleanText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _imageUrl(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return _isUsableUrl(trimmed) ? trimmed : null;
    }

    if (value is List) {
      for (final item in value) {
        final candidate = _imageUrl(item);
        if (candidate != null) return candidate;
      }
      return null;
    }

    if (value is Map) {
      for (final key in const ['url', 'contentUrl']) {
        final candidate = _imageUrl(value[key]);
        if (candidate != null) return candidate;
      }
    }

    return null;
  }

  bool _isUsableUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  String? _fallbackTitle(Document document) {
    return _firstElementText(_itemPropElements(document, 'name')) ??
        _firstElementText(document.querySelectorAll('h1')) ??
        _firstElementText(document.querySelectorAll('title'));
  }

  String? _fallbackImageUrl(Document document) {
    for (final element in _itemPropElements(document, 'image')) {
      for (final key in const ['src', 'content', 'href']) {
        final value = element.attributes[key]?.trim();
        if (value != null && _isUsableUrl(value)) {
          return value;
        }
      }
    }

    return null;
  }

  List<String> _itemPropText(Document document, String itemProp) {
    final values = <String>[];
    final elements = _itemPropElements(
      document,
      itemProp,
    ).where((element) => !_hasAncestorWithItemProp(element, itemProp));

    for (final element in elements) {
      values.addAll(_elementTextEntries(element));
    }

    return values;
  }

  Iterable<Element> _itemPropElements(Document document, String itemProp) {
    return document
        .querySelectorAll('[itemprop]')
        .where((element) => _hasItemProp(element, itemProp));
  }

  bool _hasItemProp(Element element, String itemProp) {
    final attribute = element.attributes['itemprop'];
    if (attribute == null) return false;

    return attribute.split(RegExp(r'\s+')).contains(itemProp);
  }

  bool _hasAncestorWithItemProp(Element element, String itemProp) {
    Element? parent = element.parent;
    while (parent != null) {
      if (_hasItemProp(parent, itemProp)) {
        return true;
      }
      parent = parent.parent;
    }

    return false;
  }

  List<String> _elementTextEntries(Element element) {
    final nestedListItems = element.localName == 'li'
        ? const <Element>[]
        : element.querySelectorAll('li');

    if (nestedListItems.isNotEmpty) {
      return nestedListItems
          .map((item) => _cleanText(item.text))
          .where((entry) => entry.isNotEmpty)
          .toList();
    }

    return _cleanTextEntries(element.text);
  }

  String? _firstElementText(Iterable<Element> elements) {
    for (final element in elements) {
      final text = _cleanText(element.text);
      if (text.isNotEmpty) return text;
    }

    return null;
  }
}
