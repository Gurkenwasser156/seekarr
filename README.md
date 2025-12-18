# Seekarr

A Flutter mobile application for managing self-hosted media services including Jellyseerr, Radarr, Sonarr, and Lidarr.

## Features

- **Discover**: Browse trending movies and TV shows via Jellyseerr integration
  - **Manage Media**: View requests, delete media from Radarr/Sonarr, clear data
- **Movies**: View and manage your Radarr movie library
- **TV Series**: View and manage your Sonarr TV series library
- **Music**: View and manage your Lidarr music library
- **Search**: Search across all sections with always-visible search bars
  - Discover: Search movies and TV shows via Jellyseerr
  - Movies: Lookup movies via Radarr
  - Series: Lookup TV series via Sonarr
  - Music: Lookup artists via Lidarr
- **Activity**: Monitor download queues, history, and wanted items across all services
- **Pull-to-Refresh**: Swipe down on any screen to refresh data
- **iOS-style Navigation**: Swipe from left edge to go back on detail screens
- **Material You**: Dynamic theming based on system colors

## Architecture

```
lib/
├── core/
│   ├── api/           # API client and shared service mixin (ArrActivityMixin)
│   ├── models/        # Shared data models
│   ├── utils/         # Utilities (image, URL, routing)
│   └── widgets/       # Shared widgets (ContentCard, MediaGrid, ReleaseListItem, etc.)
├── features/
│   ├── discover/      # Jellyseerr integration
│   │   └── presentation/widgets/  # RequestBottomSheet
│   ├── movies/        # Radarr integration
│   ├── series/        # Sonarr integration
│   ├── music/         # Lidarr integration
│   ├── settings/      # App configuration
│   ├── shell/         # Navigation shell
│   └── activity/      # Queue/History/Wanted views
│       └── presentation/widgets/  # ActivityTabHelpers mixin
└── main.dart
```

## Getting Started

1. Install Flutter SDK
2. Clone this repository
3. Run `flutter pub get`
4. Run `flutter run`

## Configuration

Configure your service URLs and API keys in the Settings screen:
- Jellyseerr URL + API Key
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

## Technologies

- Flutter 3.x
- Riverpod for state management
- GoRouter for navigation
- Dio for HTTP requests
- CachedNetworkImage for image caching
