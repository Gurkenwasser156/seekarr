# Seekarr

A Flutter mobile application for managing self-hosted media services.
Supported services are: Seerr, Radarr, Sonarr, and Lidarr.

## Project Notes
This project is being developed with heavy use of OpenCode. 
The main purpose of this project is to solve a personal need: to flawlessly manage my self-hosted *arr stack with my phone, from anywhere.

Despite the use of LLMs, my priority with this app is to push Agentic Coding to its limits, thus seeking the best coding quality possible. Any feedback and contribution will always be appreciated.

The application is under active development and contributions are welcome.

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

## Screenshots
WIP

## Getting Started

Before running Seekarr locally, make sure you have:

- A Flutter SDK version compatible with Dart `^3.10.0`
- Xcode for iOS/macOS development
- Android Studio and the Android SDK for Android development
- Access to at least one supported self-hosted service:
  - Seerr
  - Radarr
  - Sonarr
  - Lidarr

1. Clone this repository
2. Run `flutter pub get`
3. Run `flutter run`

## Testing

Run unit tests:
```bash
flutter test
```

## Configuration

Seekarr does not ship with any server credentials or default service configuration.

After launching the app, open the Settings screen and configure the services you want to use:

Seerr URL + API key
Radarr URL + API key
Sonarr URL + API key
Lidarr URL + API key
Region preferences where applicable
API keys are stored locally on the device using secure storage.


## Technologies

- Flutter 3.x
- Riverpod for state management
- GoRouter for navigation
- Dio for HTTP requests
- CachedNetworkImage for image caching

## Architecture / Development

Seekarr uses a feature-first structure:

- `lib/core/` for shared infrastructure, theme, routing, utilities, API helpers, and reusable widgets
- `lib/features/<feature>/` for feature-specific code split into:
  - `data/`
  - `domain/`
  - `presentation/`

Main technical choices:

- Flutter for the app
- Riverpod for state management
- go_router for navigation
- Dio for HTTP requests

**The main goals of the codebase are readability, modularity, and reusable UI components.**

## Contributing
Contributions are **very** welcome.
Anyway, I work on this project on my spare time and will take care of PRs, issues and discussions whenever I can.

If you wish to work on a change, please open an issue first so the scope and direction can be discussed before implementation.

For contribution guidelines, setup notes, and pull request expectations, see **CONTRIBUTING.md**.

## License
This project is licensed under the **MIT License**