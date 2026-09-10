class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    this.sourceUrl,
    this.imageUrl,
  });

  final String id;
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final String? sourceUrl;
  final String? imageUrl;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients,
      'instructions': instructions,
      'sourceUrl': sourceUrl,
      'imageUrl': imageUrl,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      ingredients: List<String>.from(map['ingredients'] as List),
      instructions: List<String>.from(map['instructions'] as List),
      sourceUrl: map['sourceUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
