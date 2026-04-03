# Important Disclaimer

The main purpose of this project is to solve a personal need: to flawlessly manage my self-hosted *arr stack with my phone, from anywhere.

My priority with this app is the best coding quality possible.

# Seekarr

A Flutter mobile application for managing self-hosted media services.
Supported services are: Seerr, Radarr, Sonarr, and Lidarr.

## Features

- **Discover**: Browse trending movies and TV shows via Seerr integration
  - **Rich Details**: View backdrops, content ratings, watch providers, trailers, release dates, seasons, and collections
  - **Manage Media**: View requests, delete media from Radarr/Sonarr, clear data
- **Movies**: View and manage your Radarr movie library
- **TV Series**: View and manage your Sonarr TV series library
- **Music**: View and manage your Lidarr music library
- **Search**: Search across all sections with always-visible search bars
- **Activity**: Comprehensive task monitoring
  - **Activity Tab**: Segmented sticky navigation for Queue, History, and Blocklist with full pagination fetching.
  - **Wanted Tab**: Segmented sticky navigation for Missing and Cutoff Unmet with status text and pagination.
  - **Queue Management**: Queue status normalization based on structured fields, with manual import placeholder actions.
  - **History Cleanup**: Clean presentation showing date-only, size in GB, without noisy metadata.
  - **Smart Search**: Wanted auto + interactive search actions using shared existing modules.
  - **Hierarchical Sonarr**: Sonarr wanted presentation is structured by Series > Season > Episode, including per-episode search actions.
- **Multiplatform**: Currently working and tested for Android, iOS and MacOS
- **Material Design 3**: Modern design with Seerr-inspired color palette

## Architecture

```
lib/
├── core/
│   ├── api/           # API client and shared service mixin (ArrActivityMixin)
│   ├── models/        # Shared data models
│   ├── utils/         # Utilities (image, URL, routing)
│   └── widgets/       # Shared widgets (ContentCard, MediaGrid, ReleaseListItem, etc.)
├── features/
│   ├── discover/      # Seerr integration
│   │   └── presentation/widgets/  # RequestBottomSheet
│   ├── movies/        # Radarr integration
│   ├── series/        # Sonarr integration
│   ├── music/         # Lidarr integration
│   ├── settings/      # App configuration
│   ├── shell/         # Navigation shell
│   └── activity/      # Redesigned top-level Activity and Wanted views
│       └── presentation/widgets/  # Decomposed widgets, shared search helpers, and simplified segment enums
└── main.dart
```

## Getting Started

1. Install Flutter SDK
2. Clone this repository
3. Run `flutter pub get`
4. Run `flutter run`

## Configuration

Configure your service URLs, API keys, and app preferences in the Settings screen:
- General settings (e.g. Region for watch providers)
- Seerr URL + API Key
- Radarr URL + API Key
- Sonarr URL + API Key
- Lidarr URL + API Key

## Testing
  
Run unit tests:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

*Note for Contributors:* When working on the Activity and Wanted modules, adhere to the established architecture: use structured fields for queue status normalization, reuse the central shared helpers for search actions and activity widgets, and ensure paginated data fetching. Keep widget files decomposed and use simplified segment enums.

## Technologies

- Flutter 3.x
- Riverpod for state management
- GoRouter for navigation
- Dio for HTTP requests
- CachedNetworkImage for image caching
