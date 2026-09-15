import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_page_service.dart';

class RecipeUrlImportScreen extends StatefulWidget {
  const RecipeUrlImportScreen({super.key, this.pageService, this.parser});

  final RecipePageService? pageService;
  final RecipePageParser? parser;

  @override
  State<RecipeUrlImportScreen> createState() => _RecipeUrlImportScreenState();
}

class _RecipeUrlImportScreenState extends State<RecipeUrlImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  late final RecipePageService _pageService;
  late final RecipePageParser _parser;
  String? _submittedUrl;
  Recipe? _parsedRecipe;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageService = widget.pageService ?? RecipePageService();
    _parser = widget.parser ?? RecipePageParser();
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter a recipe URL.';

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return 'Enter a valid http or https URL.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmed = _url.text.trim();
    final uri = Uri.parse(trimmed);
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _submittedUrl = null;
      _parsedRecipe = null;
    });

    try {
      // First we download the page. The returned text is the complete HTML
      // document, not just the URL, so the next step has real page data.
      final pageText = await _pageService.fetch(uri);

      // This is the handoff from networking to parsing. Keeping this line
      // separate makes it clear that the parser receives the downloaded page.
      final recipe = _parser.parse(pageText, sourceUrl: trimmed);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submittedUrl = trimmed;
        _parsedRecipe = recipe;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe page retrieved successfully.')),
      );
    } on RecipePageFetchException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong while importing the recipe.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import Recipe URL')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Bring in a recipe from the web',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste the recipe page URL to retrieve and read the recipe.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('recipeUrlField'),
                  controller: _url,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Recipe URL',
                    hintText: 'https://example.com/recipes/soup',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateUrl,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('importRecipeUrlButton'),
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    _isLoading ? 'Retrieving page...' : 'Import Recipe',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    key: const Key('recipeImportError'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                if (_submittedUrl != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ready for import',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SelectableText(_submittedUrl!),
                          const SizedBox(height: 12),
                          Text(
                            _parsedRecipe == null
                                ? 'The page was retrieved, but no structured recipe was found.'
                                : 'Found recipe: ${_parsedRecipe!.title}',
                          ),
                          if (_parsedRecipe != null) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              key: const Key('useImportedRecipeButton'),
                              onPressed: () =>
                                  Navigator.of(context).pop(_parsedRecipe),
                              icon: const Icon(Icons.check),
                              label: const Text('Use This Recipe'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
