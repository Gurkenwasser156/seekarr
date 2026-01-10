# AGENTS.md - Seekarr Development Guidelines

Guidelines for agentic coding agents working on this Flutter project.

## Build/Lint/Test Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Run ALL tests
flutter test

# Run SINGLE test file
flutter test test/features/movies/data/radarr_service_test.dart

# Run tests for a feature
flutter test test/features/movies/

# Run with verbose output
flutter test --verbose

# Static analysis (linting)
flutter analyze

# Format code
dart format .

# Build
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

## Architecture

Clean Architecture with feature-based organization:

```
lib/
├── core/                    # Shared infrastructure
│   ├── api/                 # ApiClient, BaseArrService, mixins
│   ├── models/              # Shared models (MediaPreview)
│   ├── widgets/             # Reusable UI (AsyncValueWidget, etc.)
│   ├── app_spacing.dart     # Spacing tokens (4dp grid)
│   ├── app_radius.dart      # Border radius tokens
│   └── theme.dart           # Material 3 theming, AppColors
└── features/<feature>/
    ├── domain/models/       # Domain models (RadarrMovie, etc.)
    ├── data/                # Services (RadarrService, etc.)
    └── presentation/
        ├── screens/         # Screen widgets
        ├── providers/       # Riverpod providers
        └── widgets/         # Feature-specific widgets
```

## State Management (Riverpod)

- Use `Provider` for service dependencies
- Use `FutureProvider` for async data fetching
- Use `ConsumerWidget` for UI that consumes state
- Always validate configuration in service providers

## API/Service Layer

- Services use `ArrActivityMixin` for shared activity operations
- Use `ApiClient` for all HTTP requests
- Return empty lists on API failures (graceful degradation)
- Throw exceptions for missing configuration

```dart
Future<List<RadarrMovie>> getMovies() async {
  try {
    final response = await client.get('/api/v3/movie');
    final data = response.data as List<dynamic>;
    return data.map((e) => RadarrMovie.fromJson(e)).toList();
  } catch (e) {
    return []; // Graceful fallback
  }
}
```

## Design Tokens

Use design system tokens instead of hardcoded values:

```dart
padding: const EdgeInsets.all(AppSpacing.lg),  // 16dp
gap: AppSpacing.sm,                             // 8dp
borderRadius: AppRadius.borderRadiusMd,
color: Theme.of(context).colorScheme.primary,
backgroundColor: AppColors.surfaceDark,
style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
```

**Spacing scale:** xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48

## Import Organization

Order imports as follows:
1. Flutter/Dart SDK
2. Package imports (third-party)
3. Project imports (absolute `package:seekarr/...`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:seekarr/core/api/api_client.dart';
import 'package:seekarr/features/movies/domain/models/radarr_movie.dart';
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `radarr_service.dart` |
| Classes | PascalCase | `RadarrService`, `MovieDetailsScreen` |
| Mixins | PascalCase + Mixin | `ArrActivityMixin` |
| Methods/Variables | camelCase | `getMovies()`, `movieId` |
| Private members | _prefix | `_buildTextTheme()` |
| Constants | camelCase in class | `AppSpacing.lg`, `AppColors.primary` |

## Model Classes

- Include `fromJson()` factory constructor
- Handle null values with defaults in JSON parsing
- Use `const` constructors where possible

```dart
factory RadarrMovie.fromJson(Map<String, dynamic> json) {
  return RadarrMovie(
    id: json['id'] ?? 0,
    title: json['title'] ?? 'Unknown',
    genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );
}
```

## Error Handling

**Service layer:** Try-catch with fallback values
```dart
try { /* API call */ } catch (e) { return []; }
```

**UI layer:** Use `AsyncValueWidget` for loading/error states

## Testing

- Mirror source structure in `test/` directory
- Use descriptive test names explaining behavior
- Group related tests with `group()`

```dart
void main() {
  group('RadarrService', () {
    group('getMovieByTmdbId', () {
      test('finds movie when TMDB ID matches', () { /* ... */ });
    });
  });
}
```

## UI Patterns

- Material Design 3 components only
- `AsyncValueWidget` for loading/error states
- Pull-to-refresh on list screens
- `Hero` animations with consistent tagging
- `CupertinoPage` for detail screen transitions

## Code Quality

- All code must pass `flutter analyze` without warnings
- Run `dart format .` before committing
- Write tests for new features and bug fixes
- Use `const` constructors where possible
