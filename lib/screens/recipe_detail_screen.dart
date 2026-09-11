import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_database_service.dart';
import 'add_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.databaseService,
  });

  final Recipe recipe;
  final RecipeDatabaseService databaseService;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute(
        builder: (_) => AddRecipeScreen(
          databaseService: widget.databaseService,
          recipe: _recipe,
        ),
      ),
    );
    if (mounted && updated != null) setState(() => _recipe = updated);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text(
          'Delete “${_recipe.title}” from your saved recipes? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.databaseService.deleteRecipe(_recipe.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the recipe. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_deleting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Detail'),
          actions: [
            IconButton(
              tooltip: 'Edit Recipe',
              onPressed: _deleting ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete Recipe',
              onPressed: _deleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_deleting) const LinearProgressIndicator(),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _recipe.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_recipe.ingredients.length} ingredients · ${_recipe.instructions.length} steps',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Ingredients', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final ingredient in _recipe.ingredients)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(
                          child: Text(
                            ingredient,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 32),
                Text('Instructions', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                for (
                  var index = 0;
                  index < _recipe.instructions.length;
                  index++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recipe.instructions[index],
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_recipe.sourceUrl?.isNotEmpty == true) ...[
                  const Divider(height: 32),
                  Text('Source', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(_recipe.sourceUrl!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
