import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_deck/main.dart';

void main() {
  testWidgets('navigates between recipe list, add recipe, and recipe detail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeDeckApp());

    expect(find.text('Recipe Deck'), findsOneWidget);
    expect(find.text('Classic Pancakes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addRecipeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Recipe'), findsOneWidget);
    expect(find.text('Add recipe form will go here.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Recipe Deck'), findsOneWidget);
    expect(find.text('Classic Pancakes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sampleRecipeTile')));
    await tester.pumpAndSettle();

    expect(find.text('Recipe Detail'), findsOneWidget);
    expect(find.text('Classic Pancakes'), findsOneWidget);
    expect(find.text('Recipe details will go here.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Recipe Deck'), findsOneWidget);
    expect(find.text('Classic Pancakes'), findsOneWidget);
  });
}
