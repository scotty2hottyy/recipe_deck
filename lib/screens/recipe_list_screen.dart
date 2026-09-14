import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_database_service.dart';
import '../services/recipe_page_service.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_url_import_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({
    super.key,
    this.databaseService,
    this.recipePageService,
  });

  final RecipeDatabaseService? databaseService;
  final RecipePageService? recipePageService;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late final RecipeDatabaseService _database;
  late Future<List<Recipe>> _recipes;

  @override
  void initState() {
    super.initState();
    _database = widget.databaseService ?? RecipeDatabaseService();
    _recipes = _database.getAllRecipes();
  }

  void _reload() {
    setState(() {
      _recipes = _database.getAllRecipes();
    });
  }

  Future<void> _openRecipe(Recipe recipe) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            RecipeDetailScreen(recipe: recipe, databaseService: _database),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _addRecipe() async {
    final saved = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute(
        builder: (_) => AddRecipeScreen(
          databaseService: _database,
          recipePageService: widget.recipePageService,
        ),
      ),
    );
    if (mounted && saved != null) _reload();
  }

  Future<void> _importRecipeUrl() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            RecipeUrlImportScreen(pageService: widget.recipePageService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Deck'),
        actions: [
          IconButton(
            key: const Key('openRecipeUrlImportButton'),
            tooltip: 'Import Recipe URL',
            onPressed: _importRecipeUrl,
            icon: const Icon(Icons.link),
          ),
        ],
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your recipes.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }
          final recipes = snapshot.data!;
          if (recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your recipe deck starts here',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first recipe to keep it close at hand.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _addRecipe,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Recipe'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _importRecipeUrl,
                      icon: const Icon(Icons.link),
                      label: const Text('Import from URL'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Card(
                    child: ListTile(
                      key: ValueKey(recipe.id),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(recipe.title),
                      subtitle: Text(
                        '${recipe.ingredients.length} ingredients · ${recipe.instructions.length} steps',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openRecipe(recipe),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addRecipeButton'),
        tooltip: 'Add Recipe',
        onPressed: _addRecipe,
        child: const Icon(Icons.add),
      ),
    );
  }
}
