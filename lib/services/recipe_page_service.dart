import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'recipe_text.dart';

/// This function describes the one network operation that the importer needs.
///
/// Keeping the operation in a small function makes the service easy to test.
/// A test can give the service a pretend request function instead of calling
/// the real internet.
typedef RecipePageRequest = Future<http.Response> Function(Uri uri);

/// This error means that the recipe page could not be downloaded.
///
/// The screen catches this error and shows a friendly message. That is why a
/// temporary internet problem does not crash the whole application.
class RecipePageFetchException implements Exception {
  const RecipePageFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads the text of a recipe webpage.
class RecipePageService {
  RecipePageService({
    RecipePageRequest? request,
    this.timeout = const Duration(seconds: 15),
  }) : _request = request ?? _downloadWithHttpPackage;

  final RecipePageRequest _request;
  final Duration timeout;

  /// Gets the webpage text and gives it back to the caller.
  ///
  /// The timeout is important: a server that never answers must not leave the
  /// import button spinning forever. Non-success HTTP responses are errors too
  /// because they do not contain the recipe page we asked for.
  Future<String> fetch(Uri uri) async {
    try {
      final response = await _request(uri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RecipePageFetchException(
          'The recipe page returned HTTP ${response.statusCode}.',
        );
      }
      return response.body;
    } on RecipePageFetchException {
      rethrow;
    } on TimeoutException {
      throw const RecipePageFetchException(
        'The recipe page took too long to answer.',
      );
    } on Object {
      throw const RecipePageFetchException(
        'The recipe page could not be reached. Check your internet connection and try again.',
      );
    }
  }

  static Future<http.Response> _downloadWithHttpPackage(Uri uri) {
    return http.get(uri, headers: const {'User-Agent': 'RecipeDeck/1.0'});
  }
}

/// Reads recipe information from a downloaded HTML page.
///
/// Recipe websites commonly put their structured recipe information inside a
/// JSON-LD script tag. This parser looks there first. It does not need to know
/// which website sent the page, so the downloaded page text can be passed here
/// without the network service knowing anything about recipe fields.
class RecipePageParser {
  /// Converts page text into a [Recipe], or returns null when no recipe was
  /// found in the page.
  Recipe? parse(String pageText, {required String sourceUrl}) {
    final document = html_parser.parse(pageText);
    final scripts = document.querySelectorAll(
      'script[type="application/ld+json"]',
    );

    for (final script in scripts) {
      final recipeData = _findRecipe(_decodeJson(script.text));
      if (recipeData == null) continue;

      final title = _readString(recipeData['name']);
      final ingredients = _readStringList(recipeData['recipeIngredient']);
      final instructions = _readInstructions(recipeData['recipeInstructions']);
      if (title == null || ingredients.isEmpty || instructions.isEmpty) {
        continue;
      }

      return Recipe(
        id: sourceUrl.hashCode.toRadixString(16),
        title: title,
        ingredients: ingredients,
        instructions: instructions,
        sourceUrl: sourceUrl,
        imageUrl: _readImageUrl(recipeData['image']),
      );
    }
    return null;
  }

  dynamic _decodeJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic>? _findRecipe(dynamic value) {
    if (value is List) {
      for (final item in value) {
        final result = _findRecipe(item);
        if (result != null) return result;
      }
      return null;
    }
    if (value is! Map) return null;

    final map = Map<String, dynamic>.from(value);
    final type = map['@type'];
    final isRecipe =
        type == 'Recipe' ||
        (type is List && type.any((item) => item == 'Recipe'));
    if (isRecipe) return map;

    return _findRecipe(map['@graph']);
  }

  String? _readString(dynamic value) {
    if (value is String) {
      final text = cleanRecipeText(value);
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  List<String> _readStringList(dynamic value) {
    if (value is String) {
      final text = cleanRecipeText(value);
      return text.isEmpty ? [] : [text];
    }
    if (value is! List) return [];
    return value
        .map(_readString)
        .whereType<String>()
        .where((text) => text.isNotEmpty)
        .toList();
  }

  List<String> _readInstructions(dynamic value) {
    if (value is String) return _readStringList(value);
    if (value is! List) return [];

    return value
        .map((item) {
          if (item is String) return item;
          if (item is Map) return item['text'];
          return null;
        })
        .map(_readString)
        .whereType<String>()
        .toList();
  }

  String? _readImageUrl(dynamic value) {
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is Map) return _readImageUrl(value['url']);
    if (value is List && value.isNotEmpty) return _readImageUrl(value.first);
    return null;
  }
}
