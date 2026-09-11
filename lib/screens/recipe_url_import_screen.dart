import 'package:flutter/material.dart';

class RecipeUrlImportScreen extends StatefulWidget {
  const RecipeUrlImportScreen({super.key});

  @override
  State<RecipeUrlImportScreen> createState() => _RecipeUrlImportScreenState();
}

class _RecipeUrlImportScreenState extends State<RecipeUrlImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  String? _submittedUrl;

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final trimmed = _url.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _submittedUrl = trimmed);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe URL ready for import.')),
    );
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
                  'Paste the recipe page URL. Fetching and parsing will be connected next.',
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
                  onPressed: _submit,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Import Recipe'),
                ),
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
