# AI Handoff

## Project purpose
Recipe Deck is a Flutter app for keeping recipes locally as clean recipe cards. The intended URL-import workflow will let a user paste a recipe webpage URL, extract the recipe, and save it locally. Manual recipe management is implemented; URL import is still future work.

## Cumulative completion history
This history was reconstructed from Git commits and the earlier versions of this handoff. Historical placeholders below describe earlier milestones, not the current UI. Keep this cumulative history when updating the latest-session notes.

### Initial scaffold and handoff
- `0c613e5`: created the Flutter project, generated counter app, platform folders for Android/iOS/macOS/Linux/Windows/web, package configuration, lint configuration, starter test, and starter README.
- `cbcf0b1`: introduced `AI_HANDOFF.md` for continuity between contributors and AI sessions.
- Generated platform folders do not imply that every platform has been tested or supports the current persistence implementation.

### #1 — Initial navigation structure (completed before this session)
- Implementation: `d88cce4` on `issue-1-navigation`; merged through PR #17 at `08137ec`.
- Replaced the generated counter app with `RecipeDeckApp` and a Recipe List landing screen.
- Added navigation from the floating add button to Add Recipe, and from a temporary Classic Pancakes item to Recipe Detail, with back navigation to the list.
- Added navigation widget coverage. The historical handoff reported passing analysis and tests.
- Files: `lib/main.dart`, the three files in `lib/screens/`, and `test/widget_test.dart`.
- At that milestone the list was hard-coded and Add/Detail were placeholders. Those placeholders were replaced by #4–#8.

### #2 — Recipe data model (completed before this session)
- Implementation: `ff2fb35` on `issue-2-recipe-model`; merged through PR #18 at `19ec903`.
- Added `Recipe` in `lib/models/recipe.dart`: required string `id` and `title`, ordered string lists `ingredients` and `instructions`, and optional `sourceUrl` and `imageUrl`.
- Added `toMap()` and `Recipe.fromMap()` serialization. The model map represents list fields as lists; the database service handles JSON encoding separately.
- Added four tests in `test/recipe_test.dart` for required values, optional URL defaults/values, and serialization round trips. The historical handoff reported passing analysis and tests.
- The model did not yet drive the placeholder screens at that milestone; current navigation now passes full Recipe objects.

### #3 — Local recipe database (completed before this session)
- Implementation: `51bb02a` on `issue-3-local-database`; merged through PR #19 at `2399a07`.
- Added `RecipeDatabaseService` in `lib/services/recipe_database_service.dart` using `sqflite` and `path`, with injectable database factory/path for tests.
- Database: `recipe_deck.db`, schema version 1, table `recipes`. `id` is the text primary key; title, ingredients, and instructions are required. Source/image URL columns are nullable. Ingredients/instructions are stored as JSON strings.
- Added `saveRecipe` (replace on matching id), `getRecipeById`, `getAllRecipes` (title order), and `close`.
- Added SQLite FFI tests for save/read, listing, and persistence after closing/reopening. Updated dependency files and macOS plugin registration. The historical handoff reported passing analysis and tests.
- The UI was not connected to SQLite yet. #4–#8 connected it, reused save/upsert for editing, and added deletion without a schema migration.

### #4–#8 — Recipe management (completed in this session)
- Implementation: `f155939` on `issues-4-8-recipe-management`, authored by `williamfaulk04-blip` and pushed to the same branch on origin.
- #4: saved-recipe list, empty state, detail navigation, and reloads.
- #5: validated manual entry saved to SQLite and reflected in the list.
- #6: prefilled editing with identity/metadata preservation and refreshed detail/list.
- #7: confirmed deletion with persistence verified after database reopening.
- #8: scrollable detail card with ingredients and numbered instructions.
- All 14 tests passed in Android Studio, the Android build succeeded, and the user demoed and approved it.
- Issues #4–#8 were closed as completed on GitHub after publication. At the end of that operation, this feature branch had not been merged into main. Confirm current GitHub state before starting new work; issue closure alone does not imply a merge.

### #9 — Recipe URL input UI (completed in this session)
- Implementation branch: `issue-9-url-input`.
- Added a URL import screen reachable from the Recipe Deck app bar and from the empty-state screen.
- Added a recipe URL text field and import button.
- Added validation for empty input, malformed input, and non-http/non-https schemes.
- Valid http/https URLs are trimmed and submitted into a local placeholder state that displays "Ready for import" and the submitted URL. No webpage fetching, parsing, recipe creation, or database write is performed yet.
- Added widget coverage for entering a URL, empty URL rejection, invalid URL rejection, and valid URL placeholder submission.

### #11 — Parse recipe data from webpage (completed in this session)
- Implementation branch: `issue-11-recipe-parser`.
- Added parser-only recipe extraction in `lib/services/recipe_parser_service.dart`.
- Parser API: `RecipeParserService().parse(String webpageHtml)` returns `ParsedRecipeData?`, with nullable `title`, ordered `ingredients`, ordered `instructions`, and nullable `imageUrl`.
- JSON-LD is preferred over fallback HTML. The parser supports direct Recipe objects, lists containing a Recipe, `@graph` entries, `@type: "Recipe"`, and `@type` lists containing Recipe.
- Instruction parsing supports strings, lists of strings, HowToStep `text`, HowToSection `itemListElement`, nested sections/step lists, and ListItem-style `item` wrappers where reasonable.
- Image extraction supports JSON-LD string URLs, lists where the first usable URL wins, and image objects with `url` or `contentUrl`; fallback microdata image extraction reads common `src`, `content`, or `href` attributes.
- Missing recipe fields are represented safely as `null` or empty lists. Unsupported non-recipe HTML returns `null`. Malformed JSON-LD blocks are ignored so later JSON-LD blocks or fallback HTML can still parse.
- Added focused parser tests with inline HTML fixtures only; no network calls, database writes, or UI flow changes.
- Issue #10 webpage fetching is not present in this checkout/main: URL import still stops at the #9 placeholder state, and no fetch service/client is wired in locally.

### GitHub Actions CI and Android integration test (completed in this session)
- Added workflow file `.github/workflows/flutter-ci.yml`.
- The workflow runs on pushes and pull requests targeting `main`.
- CI checks out the repository, sets up Java 17, installs Flutter stable `3.47.1`, runs `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk`, then starts an Android emulator and runs the integration test.
- Added integration test file `integration_test/app_test.dart`.
- The integration test launches the app on Android, verifies the main Recipe Deck screen, opens the URL import screen, checks invalid URL rejection, and submits a valid URL into the current "Ready for import" placeholder flow.
- Added the Flutter SDK `integration_test` dev dependency, which updated `pubspec.yaml` and `pubspec.lock`.

## Latest implementation and workflow context
- Issues implemented in order: #4 saved recipe list, #5 manual entry, #6 editing, #7 deletion, #8 detail card, #9 URL input UI, and #11 parser-only recipe extraction. GitHub Actions CI and one Android integration test were already configured before #11.
- Branch: `issue-11-recipe-parser`.
- Working checkout: `/home/scott/Classes/CSC4330/recipe_deck`.
- Current app state: manual recipe management remains backed by SQLite. URL import still has the #9 validation-only placeholder submission; #11 adds a raw-HTML parser service but does not fetch webpages, show previews, save parsed recipes, or mutate the URL import UI.
- Issue #10 webpage fetching is absent from local `main`/this branch based on current files and branch history. There is no local network-fetch service for the parser to consume yet.
- User requires a thorough change breakdown and a chance to demo before approving any commit. Do not merge to main.
- Include this handoff in every commit.

## What changed
- `lib/services/recipe_parser_service.dart`: new parser service and `ParsedRecipeData` result model. JSON-LD Recipe data is parsed first, then lightweight itemprop HTML fallback is attempted only when no usable JSON-LD Recipe is found.
- `test/recipe_parser_service_test.dart`: new focused tests using inline HTML fixtures for direct JSON-LD, `@graph`, HowToStep, HowToSection/nested instructions, missing fields, malformed JSON-LD, unsupported pages, fallback HTML, and JSON-LD priority.
- `pubspec.yaml` / `pubspec.lock`: added the `html` package for DOM parsing; lockfile also includes its `csslib` transitive dependency.
- `AI_HANDOFF.md`: updated for Issue #11 status, parser behavior, files changed, validation, and next task context.
- No URL import UI, networking, SQLite behavior, or GitHub Actions files were changed for Issue #11.

## Parser behavior
- `RecipeParserService().parse(String webpageHtml)` returns `ParsedRecipeData?`.
- JSON-LD supported shapes: Recipe object directly, list containing a Recipe, nested Recipe object such as inside `@graph`, `@type` equal to `Recipe`, and `@type` list containing `Recipe`.
- Extracts `name` to `title`, `recipeIngredient` to trimmed nonblank ingredients, `recipeInstructions` to trimmed nonblank instructions, and common JSON-LD image URL shapes to `imageUrl`.
- Instruction support includes string, list of strings, HowToStep `text`, HowToSection `itemListElement`, nested sections/steps, and ListItem-style `item` wrappers where reasonable.
- Fallback support, used only without a usable JSON-LD Recipe: title from itemprop `name`, `h1`, or document `title`; ingredients from itemprop `recipeIngredient`; instructions from itemprop `recipeInstructions`; image from itemprop `image` when a usable URL is readily available.
- Graceful failure: unsupported/non-recipe HTML returns `null`; malformed JSON-LD is skipped; missing title/image become `null`; missing ingredient/instruction fields become empty lists.

## Validation
- Issue #11 parser-only targeted validation:
  - `flutter test test/recipe_parser_service_test.dart`: passed, all 11 parser tests.
- Full latest Issue #11 validation:
  - `flutter pub get`: passed.
  - `dart format .`: passed; formatted the new parser service and parser test file.
  - `flutter analyze`: passed, no issues found.
  - `flutter test`: passed, all 29 tests.
  - `git diff --check`: passed.
- Previous #9 validation passed with `flutter analyze`, `flutter test` across 18 tests, and `git diff --check`.
- Previous #4–#8 validation passed in Android Studio with all 14 tests passing at that time.

## GitHub CI notes
- Workflow filename: `.github/workflows/flutter-ci.yml`.
- Integration test filename: `integration_test/app_test.dart`.
- CI starts on pushes to `main` and pull requests targeting `main`; branch pushes to non-main branches will not run this workflow until a PR targets `main`.
- The Android integration test uses `reactivecircus/android-emulator-runner@v2` with API level 35, `google_apis`, x86_64, and a Pixel 6 profile.
- If CI fails, check the failing step first: dependency resolution for Flutter version mismatches, analyzer/test failures for app changes, Gradle/Android SDK output for APK build failures, and emulator boot/device logs for integration-test failures.
- If the emulator step becomes flaky, confirm GitHub's runner image still supports KVM and that the selected API level/target image is available.

## Current limitations / next work
- Runtime persistence uses the existing sqflite Android/iOS/macOS implementation; Chrome persistence is not configured. Use the Android emulator for this demo.
- No hard-coded sample recipes are inserted. A fresh database displays an empty state.
- URL import does not fetch webpage content yet in this checkout. It only captures and validates a URL, then stores the submitted URL in transient screen state.
- Next likely task should be Issue #12: connect fetched HTML -> parser -> preview/save flow, once the Issue #10 fetching work is available locally or merged.
- After pushing this branch, open or update a pull request targeting `main` to trigger the new CI workflow on GitHub.
- Search/filtering and broader polish remain future issues.
