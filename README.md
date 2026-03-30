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
- **Activity**: Monitor download queues, history, and wanted items across all services
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

## Technologies

- Flutter 3.x
- Riverpod for state management
- GoRouter for navigation
- Dio for HTTP requests
- CachedNetworkImage for image caching
