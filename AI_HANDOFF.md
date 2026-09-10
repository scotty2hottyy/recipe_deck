# AI Handoff

## What was just completed
- Issue/task: GitHub Issue #3 - local recipe database.
- Branch: `issue-3-local-database`.
- What changed: Added a small SQLite-backed `RecipeDatabaseService` for saving recipes, reading a recipe by id, and reading all recipes. Recipe list fields are stored as JSON strings to keep the database schema simple. Added desktop-friendly sqflite FFI tests for save/read behavior and persistence after closing and reopening the database.
- Important files changed:
  - `lib/services/recipe_database_service.dart`
  - `test/recipe_database_service_test.dart`
  - `pubspec.yaml`
  - `pubspec.lock`
  - `macos/Flutter/GeneratedPluginRegistrant.swift`
  - `AI_HANDOFF.md`

## Current project state
- What currently works:
  - App launches directly to the Recipe List screen.
  - The list shows a temporary `Classic Pancakes` recipe.
  - Tapping the add button opens the Add Recipe screen.
  - Tapping the sample recipe opens the Recipe Detail screen.
  - Back navigation returns to the Recipe List screen from both placeholder screens.
  - Recipe objects can now be created with `id`, `title`, `ingredients`, `instructions`, `sourceUrl`, and `imageUrl`.
  - Recipe objects can be converted to and restored from a map.
  - Recipe objects can be saved locally in SQLite and read back through the service layer.
  - Database tests run with `sqflite_common_ffi`, so they do not need an Android device.
  - `flutter analyze` passes.
  - `flutter test` passes.
- Known problems:
  - Recipe data is still hard-coded as a temporary placeholder.
  - Add Recipe and Recipe Detail screens intentionally do not have real form, model, persistence, or database logic yet.
  - The UI does not use the database service yet.

## What should happen next
- Next likely task: Connect the Recipe List/Add Recipe flow to the `RecipeDatabaseService` or build the first real add-recipe form.
- Relevant files:
  - `lib/models/recipe.dart`
  - `lib/services/recipe_database_service.dart`
  - `lib/screens/recipe_list_screen.dart`
  - `lib/screens/recipe_detail_screen.dart`
  - `lib/screens/add_recipe_screen.dart`
  - `test/recipe_database_service_test.dart`
  - `test/recipe_test.dart`
- Suggested approach: Keep the database service separate from widgets and pass `Recipe` objects through the existing navigation routes before adding edit/delete behavior.
- Anything to avoid/beware of: Do not add edit/delete UI or URL import logic until the related issue calls for it.
