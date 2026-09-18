import 'dart:math';

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_database_service.dart';
import '../services/recipe_page_service.dart';
import 'recipe_url_import_screen.dart';

/// Shared form for manual entry and editing an existing recipe.
class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({
    super.key,
    required this.databaseService,
    this.recipePageService,
    this.recipe,
    this.importedRecipe,
  });

  final RecipeDatabaseService databaseService;
  final RecipePageService? recipePageService;
  final Recipe? recipe;

  /// Initial values for a new import; unlike [recipe], this does not reuse its ID.
  final Recipe? importedRecipe;

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _ingredients;
  late final TextEditingController _instructions;
  String? _sourceUrl;
  String? _imageUrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.recipe ?? widget.importedRecipe;
    _title = TextEditingController(text: initial?.title ?? '');
    _ingredients = TextEditingController(
      text: initial?.ingredients.join('\n') ?? '',
    );
    _instructions = TextEditingController(
      text: initial?.instructions.join('\n') ?? '',
    );
    _sourceUrl = initial?.sourceUrl;
    _imageUrl = initial?.imageUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _instructions.dispose();
    super.dispose();
  }

  List<String> _lines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final original = widget.recipe;
    final recipe = Recipe(
      id:
          original?.id ??
          '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000000)}',
      title: _title.text.trim(),
      ingredients: _lines(_ingredients.text),
      instructions: _lines(_instructions.text),
      sourceUrl: _sourceUrl ?? original?.sourceUrl,
      imageUrl: _imageUrl ?? original?.imageUrl,
    );
    try {
      await widget.databaseService.saveRecipe(recipe);
      if (mounted) Navigator.of(context).pop(recipe);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your recipe. Please try again.';
        });
      }
    }
  }

  Future<void> _importFromUrl() async {
    if (_saving) return;
    final recipe = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute(
        builder: (_) =>
            RecipeUrlImportScreen(pageService: widget.recipePageService),
      ),
    );
    if (!mounted || recipe == null) return;

    setState(() {
      _title.text = recipe.title;
      _ingredients.text = recipe.ingredients.join('\n');
      _instructions.text = recipe.instructions.join('\n');
      _sourceUrl = recipe.sourceUrl;
      _imageUrl = recipe.imageUrl;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.recipe == null ? 'Add Recipe' : 'Edit Recipe'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'A recipe worth keeping',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Give it a name, then add one ingredient or step per line.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('recipeTitleField'),
                    controller: _title,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a recipe title.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('recipeIngredientsField'),
                    controller: _ingredients,
                    enabled: !_saving,
                    minLines: 4,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients',
                      helperText:
                          'One ingredient per line, including quantities.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _lines(value ?? '').isEmpty
                        ? 'Enter at least one ingredient.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('recipeInstructionsField'),
                    controller: _instructions,
                    enabled: !_saving,
                    minLines: 5,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                      helperText: 'One step per line, in cooking order.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _lines(value ?? '').isEmpty
                        ? 'Enter at least one instruction.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('importRecipeOnAddScreenButton'),
                    onPressed: _saving ? null : _importFromUrl,
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: const Text('Import from URL'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('saveRecipeButton'),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Saving…' : 'Save Recipe'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
