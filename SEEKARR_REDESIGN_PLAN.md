# Seekarr Redesign Development Plan

## Status

In progress. Services, Search, and Activity redesign slices are implemented with focused tests passing. Remaining work is detail/library polish, Settings polish, final visual QA, and full-suite verification.

Completed slices:
- Theme token alignment and service accent metadata.
- Four-tab Services, Activity, Search, Settings navigation model.
- Services/Search/Activity shell routes and legacy redirects to Services.
- Floating navbar restyle to prototype glass pill while preserving drag/bounce mechanics.
- Services aggregate dashboard, service dashboard shell, all requests, and all media routes.
- Global Search data contract and grouped Search UI.
- Global Activity aggregation and seven-tab Activity UI.
- Manual import affordances removed from Activity/queue detail for this phase.

## Reference Prototype

- Canonical prototype source: local `index.html` at the repository root.
- Open Design MCP is no longer available. Do not depend on MCP calls for prototype refresh or inspection.
- Previous Open Design metadata, retained only as historical context: project `Seekarr`, id `38b64b20-fc35-43fc-8119-bd0a1a68de54`, rules file `morcg9me-rules.md`.
- Required refresh after any context reset: read the local `index.html` file directly with the repository file tools.
- Key prototype sections:
- Design tokens: `index.html` lines 9-40
- Flutter Widget Map: `index.html` lines 720-1329
- Screen list: `index.html` lines 660-676
- Navigation rendering and parent-tab mapping: `index.html` lines 4299-4328
- Services aggregate dashboard: `index.html` lines 3250-3384
- Service detail picker/subscreen pattern: `index.html` lines 3385-3470
- Global search screen: `index.html` lines 2830-2939
- Activity tabs: `index.html` lines 2942-3120
- Notifications: `index.html` lines 3121-3153
- Settings: `index.html` lines 3154-3247
- All requests: `index.html` lines 3472-3540
- All media grids: `index.html` lines 3541-3650
- Artist detail: `index.html` lines 3650-3719
- Import flow docs: `index.html` lines 1342-1773, explicitly out of scope for this plan except where backend/API notes are useful later.

## Non-Negotiable Constraints

- Preserve the current `FloatingBottomNavBar` drag and elastic bounce behavior.
- Do not replace the navbar with Flutter Material `NavigationBar`; only restyle/adapt the existing custom navbar.
- Ignore manual import implementation for now. Do not add import routes, import service classes, manual import screens, or import API calls in this redesign phase.
- The effective shipped UI must be identical to the Open Design prototype wherever technically possible in Flutter; any unavoidable deviation must be documented with a concrete reason.
- Keep the app in a working state after every implementation phase.

## Current Codebase Context

- App stack: Flutter, Material 3, Riverpod, `go_router`, Dio, `cached_network_image`.
- Theme already exists in `lib/core/theme.dart` with Inter registered via `assets/fonts/Inter.ttf`.
- Current navbar is `lib/core/widgets/floating_bottom_nav_bar.dart`; it already implements elastic drag/bounce with `_dragOffset`, `_applyElasticResistance`, `_onPanUpdate`, `_onPanEnd`, and `Curves.elasticOut`.
- Current routing uses one `ShellRoute` in `lib/core/router.dart` with tabs: Discover, Movies, Series, Music, Settings.
- Current `NavTab` is configurable via settings and supports hiding Movies/Series/Music.
- Current screens are service-separated; the prototype changes the mental model to Services, Activity, Search, Settings.
- Existing *arr APIs already cover libraries, lookup, queue/history/blocklist/missing/cutoff, profile updates, search, interactive release grab, and deletion.
- Seerr APIs already cover discover/trending/search, requests, details, request creation, request deletion, and media management.

## Target Product Shape

- Bottom nav becomes four top-level destinations: Services, Activity, Search, Settings.
- Services is an aggregate dashboard with four service cards: Seerr, Radarr, Sonarr, Lidarr.
- Tapping a service opens a service detail/dashboard while the selected nav tab remains Services.
- Service detail has a title dropdown/service switcher and shows service-specific stats, search, carousel/list sections, queue/missing/request sections.
- Detail screens remain pushed on top of Services and must keep Services selected in the navbar.
- Activity becomes global, not per-service-only, with tabs/segments: Activity, Queue, History, Wanted, Blocklist, Missing, Cutoff.
- Search becomes global across Seerr, Radarr, Sonarr, Lidarr and groups results by service.
- Settings follows the prototype grouping and service connection card visual language.

## Architecture Decisions

- Keep `go_router` and `ShellRoute`, but remap top-level routes to `/services`, `/activity`, `/search`, `/settings`.
- Keep existing library screens available as implementation building blocks, but make the new Services flow the primary user experience.
- Introduce service accent tokens in one shared place, not as raw colors scattered through widgets.
- Reuse existing provider/service methods where possible; add backend logic only for aggregate dashboard, global search, service health/version stats, and activity aggregation.
- Implement the navbar as a visual redesign of `FloatingBottomNavBar`, preserving its gesture/physics methods unchanged unless tests prove an adjustment is required.
- Prefer typed view models for new aggregate screens instead of passing raw maps into UI widgets.

## Out Of Scope

- Manual import UI and backend flow.
- Import picker bottom sheet from Activity.
- Manual import `GET /filesystem`, `GET /manualimport`, `POST /manualimport`, `POST /command` implementation.
- Notifications UI, route, local event aggregation, and backend/API work.
- New auth systems or remote backend services outside Seerr/Radarr/Sonarr/Lidarr APIs.
- Pixel-perfect reproduction of the HTML phone shell/status bar; the Flutter app should match the app UI, not the prototype wrapper.

## Phases And Tasks

### Phase 1: Design System Foundation

#### Task 1: Align Theme Tokens With Prototype

Description: Update the shared design tokens so dark/light surfaces, borders, text colors, radii, and service accents match the prototype.

Acceptance criteria:
- Dark tokens map to `#0f1117`, `#1c2130`, `#252d3d`, `#2d3748`, `#f0f2f8`, `#9ca3af`.
- Light tokens map to `#f3f4f6`, `#ffffff`, `#f0f1f5`, `#e2e4ea`, `#111827`, `#6b7280`.
- Service accents are available as semantic constants: Seerr `#6366f1`, Radarr `#f59e0b`, Sonarr `#8b5cf6`, Lidarr `#ec4899`.
- Existing tests for `AppTheme`, radius, spacing, chips, and cards are updated rather than removed.

Verification:
- `flutter test test/core/theme_test.dart`
- Manual check dark/light contrast on Settings, Services, and Detail screens.

Dependencies: None.

Likely files:
- `lib/core/theme.dart`
- `lib/core/app_radius.dart`
- `lib/core/app_spacing.dart`
- `test/core/theme_test.dart`

Estimated scope: Medium.

#### Task 2: Add Shared Service Metadata And Accent Utilities

Description: Centralize service labels, icons, route params, colors, and UI metadata so Services, Activity, Search, Settings, and detail pages use the same source of truth.

Acceptance criteria:
- `ServiceKey` exposes or delegates to accent color, display icon, short label, route path segment, and API family metadata.
- UI widgets no longer define ad hoc service colors.
- Existing settings/service code still reads and writes credentials unchanged.

Verification:
- `flutter test test/features/settings/domain/settings_model_test.dart`
- `flutter test test/features/settings/presentation/service_settings_screen_test.dart`

Dependencies: Task 1.

Likely files:
- `lib/features/settings/domain/service_key.dart`
- `lib/core/theme.dart` or a new `lib/core/service_metadata.dart`
- relevant tests.

Estimated scope: Small.

#### Task 3: Build Shared Prototype-Matched UI Primitives

Description: Add reusable widgets for stat chips, service cards, compact list rows, section headers, filter chips, status pills, and service-colored action buttons matching the prototype.

Acceptance criteria:
- Widgets reproduce prototype spacing: 16px screen padding, 8-12px gaps, 12px card radius, 20px large card radius, 24px pill/search radius where applicable.
- Widgets support dark/light modes and service accent colors.
- Widgets include loading/empty/error variants where they represent async data.

Verification:
- Widget tests for new primitives.
- Manual visual comparison against prototype Services, Activity, Search, Settings.

Dependencies: Tasks 1-2.

Likely files:
- `lib/core/widgets/section_header.dart`
- `lib/core/widgets/status_badge.dart`
- new shared widgets under `lib/core/widgets/`
- `test/core/widgets/*_test.dart`

Estimated scope: Medium.

### Checkpoint 1: Foundation

- `flutter test test/core/theme_test.dart test/core/widgets`
- App launches in dark and light mode.
- Navbar still drags and bounces exactly as before.
- No feature routing changes yet.

### Phase 2: Navigation And Shell

#### Task 4: Remap Top-Level Navigation To Four Prototype Tabs

Description: Change the primary navigation model from Discover/Movies/Series/Music/Settings to Services/Activity/Search/Settings while preserving hidden-tab settings only where still relevant or migrating them out if obsolete.

Acceptance criteria:
- Bottom nav shows exactly Services, Activity, Search, Settings.
- Existing detail routes under movies/series/music still work during migration.
- Detail pages and all-media subpages keep Services selected, matching prototype parent-tab mapping.
- Reselect refresh behavior still works for Services, Activity, and Search where applicable.

Verification:
- `flutter test test/features/shell/presentation/shell_screen_test.dart`
- `flutter test test/core/router_test.dart`
- Manual navigation through all four tabs and existing detail screens.

Dependencies: Task 2.

Likely files:
- `lib/features/settings/domain/nav_tab.dart`
- `lib/features/shell/presentation/shell_screen.dart`
- `lib/core/router.dart`
- settings tests that depend on hidden tabs.

Estimated scope: Medium.

#### Task 5: Restyle Floating Navbar Without Replacing Gesture Physics

Description: Match the prototype glassy floating navbar while preserving current drag/bounce code and tests.

Acceptance criteria:
- `_applyElasticResistance`, `_onPanUpdate`, `_onPanEnd`, spring controller behavior, and `Curves.elasticOut` are preserved in behavior.
- Active item is a service-colored pill with icon and label; inactive items show icon only or de-emphasized label according to available width.
- Dark navbar uses translucent `rgba(28,33,48,0.72)` equivalent; light uses translucent white equivalent.
- Safe-area padding and scroll bottom padding remain correct.

Verification:
- `flutter test test/features/shell/presentation/shell_screen_test.dart`
- Add/extend navbar widget test for drag offset reset after pan end.
- Manual drag/bounce check on device/simulator.

Dependencies: Task 4.

Likely files:
- `lib/core/widgets/floating_bottom_nav_bar.dart`
- `test/features/shell/presentation/shell_screen_test.dart`
- possibly new `test/core/widgets/floating_bottom_nav_bar_test.dart`

Estimated scope: Medium.

#### Task 6: Add Service Detail Subnavigation Pattern

Description: Implement Services as a parent route with subroutes/service state so service dashboards and media/detail pages sit on top of the Services tab.

Acceptance criteria:
- `/services` shows the aggregate dashboard.
- `/services/:service` shows the selected service dashboard.
- `/services/radarr/movie/:id`, `/services/sonarr/series/:id`, and `/services/lidarr/artist/:id` keep Services selected.
- Legacy `/discover`, `/movies`, `/series`, and `/music` redirect to the new Services flow.

Verification:
- `flutter test test/core/router_test.dart`
- Manual deep-link checks for Services dashboard, Radarr movie detail, Sonarr series detail, Lidarr artist detail.

Dependencies: Tasks 4-5.

Likely files:
- `lib/core/router.dart`
- `lib/features/shell/presentation/shell_screen.dart`
- navigation helpers/tests.

Estimated scope: Medium.

### Checkpoint 2: Navigation

- `flutter test test/core/router_test.dart test/features/shell/presentation/shell_screen_test.dart`
- Manual verify: four nav tabs, detail pages keep Services selected, navbar drag/bounce works.

### Phase 3: Services Dashboard And Service Detail

#### Task 7: Add Service Health And Summary Data Layer

Description: Add lightweight providers/view models for service connection status, version, and summary counts used by the Services aggregate dashboard.

Acceptance criteria:
- Seerr, Radarr, Sonarr, Lidarr cards can show online/offline, URL host, version if available, and summary count.
- Failures are isolated per service; one offline service does not break the dashboard.
- API calls are bounded and cached through Riverpod.

Backend/API needs:
- Use existing configured URLs/API keys.
- Add service-specific status/version calls if not present: Seerr status/settings endpoint if available, Radarr/Sonarr/Lidarr system/status endpoints.
- Use existing library calls for counts where lightweight enough; avoid full library calls if a cheaper endpoint is available.

Verification:
- Unit tests with fake services for online/offline/partial failure states.
- Manual check with one configured and one unconfigured service.

Dependencies: Tasks 1-2.

Likely files:
- new `lib/features/services/domain/service_summary.dart`
- new `lib/features/services/presentation/services_provider.dart`
- `lib/features/discover/data/seerr_service.dart`
- `lib/features/movies/data/radarr_service.dart`
- `lib/features/series/data/sonarr_service.dart`
- `lib/features/music/data/lidarr_service.dart`

Estimated scope: Medium.

#### Task 8: Build Services Aggregate Dashboard

Description: Implement the prototype Services home with service status grid, trending Seerr carousel, recent requests, recently added movies/series, and combined downloading list.

Acceptance criteria:
- Top card grid visually matches prototype: 2 columns, 16px radius, online/offline pills, service accent borders.
- Sections match prototype order: service status, Trending, Recent Requests, Recently Added Movies, Recently Added Series, Downloading.
- Section links navigate to the right service dashboard or list route.
- Empty/unconfigured states are useful and per-section, not a blank page.

Verification:
- Widget test for rendered sections with fake provider data.
- Manual dark/light comparison against prototype `screenServicesHome`.

Dependencies: Tasks 3, 6, 7.

Likely files:
- new `lib/features/services/presentation/services_screen.dart`
- shared widgets from Task 3.
- `lib/core/router.dart`

Estimated scope: Medium.

#### Task 9: Build Service Dashboard Shell With Dropdown Switcher

Description: Implement service detail dashboard structure with a title dropdown/service switcher matching the prototype and reuse existing service library/search content where possible.

Acceptance criteria:
- AppBar title displays accent dot, service name, and chevron.
- Dropdown lists Seerr, Radarr, Sonarr, Lidarr with selected checkmark and accents.
- Switching service updates content without changing selected nav tab.
- Service-specific stats/search/sections render for Seerr, Radarr, Sonarr, Lidarr.

Verification:
- Widget tests for dropdown selection and rendered service-specific title/accent.
- Manual check service switcher discoverability and route behavior.

Dependencies: Tasks 6-8.

Likely files:
- new `lib/features/services/presentation/service_dashboard_screen.dart`
- new `lib/features/services/presentation/widgets/service_switcher.dart`
- existing feature providers for discover/movies/series/music.

Estimated scope: Medium.

#### Task 10: Add All Requests And All Media Prototype Lists

Description: Implement list/grid pages for Seerr requests and service media grids using prototype filters and compact rows/cards.

Acceptance criteria:
- Seerr All Requests page shows requester, avatar/initials, status pill, type, date, and delete action.
- Radarr/Sonarr/Lidarr All Media pages show filter chips and poster grid/list matching prototype.
- Filters are initially client-side where data is already loaded; use server filters only if existing endpoints require it for scale.
- Delete/request actions retain existing confirmation behavior.

Verification:
- `flutter test test/features/activity/presentation/activity_screen_test.dart`
- Existing discover/manage request tests still pass.
- Manual check navigation from Services section links.

Dependencies: Tasks 8-9.

Likely files:
- `lib/features/activity/presentation/widgets/requests_list.dart` or new service request screen.
- new `lib/features/services/presentation/all_media_screen.dart`
- router tests.

Estimated scope: Medium.

### Checkpoint 3: Services

- `flutter test test/features/discover test/features/movies test/features/series test/features/music test/features/services` if added.
- Manual verify aggregate dashboard, each service dashboard, all requests, all media, unconfigured service handling.

### Phase 4: Global Search

#### Task 11: Add Global Search Data Contract

Description: Define a typed global search result model that can represent Seerr discover results, Radarr movies, Sonarr series, and Lidarr artists/albums.

Acceptance criteria:
- Global result includes service key, title, subtitle/meta, thumbnail/poster URL if available, status tags, action type, and destination route.
- Each service search failure is represented independently and does not fail the whole search.
- Query debounce/cancellation avoids stale results.

Backend/API needs:
- Use existing Seerr `/api/v1/search`.
- Use existing Radarr `movie/lookup`, Sonarr `series/lookup`, Lidarr `artist/lookup`.
- Optional: use local library providers to mark available/monitored/downloading if needed for prototype tags.

Verification:
- Unit tests for result grouping and partial failures.
- Fake service tests for empty query, one-service failure, mixed results.

Dependencies: Task 2.

Likely files:
- new `lib/features/search/domain/global_search_result.dart`
- new `lib/features/search/presentation/global_search_provider.dart`
- existing service classes.

Estimated scope: Medium.

#### Task 12: Build Global Search Screen

Description: Implement prototype Search tab with M3-style search bar, filter chips, service-grouped result sections, and row actions.

Acceptance criteria:
- Search tab is a top-level route `/search`.
- Results are grouped by Seerr, Radarr, Sonarr, Lidarr with accent headers and counts.
- Filter chips can show all services or one service.
- Rows match prototype compact card layout with thumbnail, title, meta, tags, and action pill/button.
- Tapping result navigates to the appropriate service/detail route.

Verification:
- Widget tests for grouped results and filtering.
- Manual search across configured services.

Dependencies: Tasks 3, 4, 11.

Likely files:
- new `lib/features/search/presentation/global_search_screen.dart`
- new search widgets.
- `lib/core/router.dart`

Estimated scope: Medium.

### Checkpoint 4: Search

- Search tests pass.
- Manual verify query, grouped results, filters, routing to details, partial service failures.

### Phase 5: Activity Redesign

#### Task 13: Add Global Activity Aggregation Layer

Description: Aggregate queue, history, blocklist, missing, cutoff, and Seerr requests into global Activity tabs while preserving existing per-service APIs.

Acceptance criteria:
- Activity tab can show recent events across services grouped by status/date where possible.
- Queue tab combines Radarr/Sonarr/Lidarr queue rows.
- History tab combines Radarr/Sonarr/Lidarr history rows.
- Wanted/Missing/Cutoff/Blocklist can show service-specific rows with service labels and accents.
- Seerr requests appear in Activity where appropriate.

Backend/API needs:
- Use existing `ArrActivityMixin` methods.
- Use existing `SeerrService.getRequests()`.
- Add typed aggregation view models; do not expose raw maps directly to new global UI.

Verification:
- Unit tests for merge ordering and partial failures.
- Existing activity tests remain passing.

Dependencies: Task 2.

Likely files:
- new `lib/features/activity/domain/global_activity_item.dart`
- new/updated `lib/features/activity/presentation/activity_provider.dart`
- existing activity widgets may be adapted.

Estimated scope: Medium.

#### Task 14: Redesign Activity Screen To Prototype Tabs

Description: Replace the current two-tab per-service Activity/Wanted presentation with the prototype single global Activity route and horizontal tab/segment bar.

Acceptance criteria:
- `/activity` shows tabs: Activity, Queue, History, Wanted, Blocklist, Missing, Cutoff.
- Activity rows match prototype compact cards with icon/thumb, title, subtitle, time/status, and chips.
- Queue rows include progress bars, percentage, quality/language/indexer chips where available.
- Wanted/Missing/Cutoff rows include auto and interactive search actions where supported.
- Manual import button is not shown in this phase.

Verification:
- `flutter test test/features/activity/presentation/activity_screen_test.dart`
- `flutter test test/features/activity/presentation/widgets/activity_item_tiles_test.dart`
- Manual check all tabs with fake/real service states.

Dependencies: Tasks 3, 13.

Likely files:
- `lib/features/activity/presentation/activity_screen.dart`
- `lib/features/activity/presentation/widgets/activity_tab.dart`
- `lib/features/activity/presentation/widgets/wanted_tab.dart`
- `lib/features/activity/presentation/widgets/activity_item_tiles.dart`
- `lib/features/activity/presentation/widgets/segment_selector.dart`

Estimated scope: Medium.

### Checkpoint 5: Activity

- Activity focused tests pass.
- Manual import UI is absent from Activity/queue detail.
- Manual visual verification of all segments, actions, and empty/error states remains pending.

### Phase 6: Detail Pages And Library Polish

#### Task 15: Align Movie And Series Detail Pages With Prototype Hero Layout

Description: Update existing Radarr/Sonarr detail screens to match the prototype: backdrop gradient, poster overlay, compact title metadata, action icon row, ratings, file/details grid, where-to-watch/tags/cast where available.

Acceptance criteria:
- Existing automatic search, interactive search, profile update, delete, monitored/file actions continue to work.
- Prototype action row visual language is used, but import action is omitted or hidden.
- Detail screens still use existing data providers and preserve hero transitions where possible.
- Missing data degrades gracefully.

Verification:
- `flutter test test/features/movies/presentation/movie_detail_screen_test.dart`
- `flutter test test/features/series/presentation/series_detail_screen_test.dart`
- Manual visual compare against Movie Detail and Series Detail prototype.

Dependencies: Tasks 1-3, 6.

Likely files:
- `lib/features/movies/presentation/movie_detail_screen.dart`
- `lib/features/series/presentation/series_detail_screen.dart`
- `lib/core/widgets/media_detail_view.dart`
- detail helper widgets/tests.

Estimated scope: Medium.

#### Task 16: Align Lidarr Artist Detail With Prototype

Description: Update artist detail to match the circular artist hero, action row, metadata grid, discography, tracklist/queue sections.

Acceptance criteria:
- Artist metadata, albums, tracks, search actions, profile update, and delete continue to work.
- Visual structure matches prototype artist detail.
- Unavailable album/track data has clear empty states.

Verification:
- `flutter test test/features/music/presentation/music_detail_screen_test.dart`
- `flutter test test/features/music/presentation/music_albums_list_test.dart`
- Manual visual compare against Artist Detail prototype.

Dependencies: Tasks 1-3, 6.

Likely files:
- `lib/features/music/presentation/music_detail_screen.dart`
- `lib/features/music/presentation/widgets/music_albums_list.dart`

Estimated scope: Medium.

#### Task 17: Align Poster Grids, Search Bars, Status Badges, And List Rows App-Wide

Description: Apply the prototype card/list/chip language to the remaining discover/library screens that feed Services and detail routes.

Acceptance criteria:
- Poster cards are 96x144-equivalent proportions with status indicator/badge language from prototype.
- Search bars use 48px height, 24px radius, service accent icon, and filter affordance where appropriate.
- Section headers and see-all links match prototype typography and spacing.
- No regression to existing search/library behavior.

Verification:
- Existing `test/core/widgets/media_grid_test.dart`, `content_card_test.dart`, `media_browse_scaffold_test.dart` pass after updates.
- Manual compare Services and All Media pages.

Dependencies: Tasks 3, 8-10, 15-16.

Likely files:
- `lib/core/widgets/media_grid.dart`
- `lib/core/widgets/content_card.dart`
- `lib/core/widgets/search_bar_header.dart`
- `lib/core/widgets/media_browse_scaffold.dart`

Estimated scope: Medium.

### Checkpoint 6: Details And Polish

- Detail and core widget tests pass.
- Manual verify movie, series, artist details and all media grids in dark/light.

### Phase 7: Settings, Notifications, Final Verification

#### Task 18: Redesign Settings Screen

Description: Align Settings with the prototype grouped cards: General, Services, About, service connection status rows, and compact icon tiles.

Acceptance criteria:
- Settings home shows General, Services, About sections in prototype order and style.
- Service rows show configured host and online/offline status where available.
- Existing appearance, services, region, and service settings routes continue to work.
- Hidden-tab settings are removed, migrated, or reframed only after confirming the new four-tab nav no longer needs user-configurable library tabs.

Verification:
- `flutter test test/features/settings/presentation/settings_home_screen_test.dart`
- `flutter test test/features/settings/presentation/settings_appearance_screen_test.dart` if present.
- Manual settings navigation and credential editing.

Dependencies: Tasks 1-3, 4, 7.

Likely files:
- `lib/features/settings/presentation/settings_home_screen.dart`
- `lib/features/settings/presentation/settings_services_screen.dart`
- `lib/features/settings/presentation/settings_appearance_screen.dart`
- settings tests.

Estimated scope: Medium.

#### Task 19: Remove Notification Affordances From This Redesign

Description: The prototype includes Notifications, but notifications are explicitly out of scope for this implementation phase.

Acceptance criteria:
- No `/notifications` route is added.
- No bell/notification icon is shown unless it opens an existing, implemented feature.
- Settings parent-tab mapping does not include a notifications exception.

Verification:
- Router/widget tests confirm no notification route is required by the shell.
- Manual check no dead-end notification action exists.

Dependencies: Task 18.

Likely files:
- `lib/core/router.dart`
- AppBar actions in Services/Search/Settings if present.

Estimated scope: Small.

#### Task 20: Final Visual QA, Regression Tests, And Documentation

Description: Verify the redesigned app against the prototype, update docs, and document any intentional deviations.

Acceptance criteria:
- Dark and light modes reviewed against prototype for Services, Service Detail, Search, Activity, Details, Settings.
- Navbar drag/bounce explicitly verified and documented.
- Manual import remains absent/deferred.
- README screenshots/docs are updated after implementation, not during planning.
- Deviations from prototype are documented with reasons.

Verification:
- `flutter test`
- `flutter analyze` if the project uses analyzer config or CI expects it.
- Manual viewport checks: small phone, standard iPhone/Android, tablet/desktop if supported.

Dependencies: All previous tasks.

Likely files:
- `README.md`
- screenshots/docs if updated.

Estimated scope: Small.

## Backend And API Work Summary

- Service health/version summary: likely new calls to `/api/v1/system/status` for Lidarr and `/api/v3/system/status` for Radarr/Sonarr; Seerr equivalent must be confirmed against actual Seerr API or omitted/fallback to a lightweight configured endpoint.
- Aggregate Services dashboard: may require fetching library counts, requests, queue summaries, and recent media from existing endpoints. Prefer existing services and cached providers.
- Global Search: requires orchestration across existing Seerr search and *arr lookup endpoints. No server-side backend is needed, but the Flutter data layer needs typed aggregation and partial failure handling.
- Global Activity: requires client-side aggregation across existing queue/history/blocklist/wanted/cutoff/request endpoints. No new remote backend is needed.
- Notifications: no existing backend identified. Treat as optional/deferred unless a real notification source exists.
- Manual import: backend/API work exists in the prototype documentation but is explicitly out of scope for this redesign phase.

## Risks And Mitigations

| Risk | Impact | Mitigation |
|---|---:|---|
| Replacing the navbar accidentally breaks drag/bounce | High | Modify `FloatingBottomNavBar` in place; add drag/bounce widget test; manual device verification at every nav checkpoint. |
| New four-tab nav conflicts with user-configurable hidden tabs | Medium | Decide migration in Task 4; do not silently drop stored settings without a compatibility path. |
| Aggregate dashboard causes too many API calls | High | Use Riverpod caching, per-service partial loading, and lightweight status endpoints. Avoid full library fetches where count/status endpoints exist. If a status/version endpoint fails, show the service as `Offline`. |
| Global search returns inconsistent shapes | Medium | Define typed `GlobalSearchResult` and normalize per service before rendering. |
| Pixel-perfect HTML concepts do not map 1:1 to Flutter | Medium | Use Flutter-native Material 3 widgets and custom widgets where needed; document unavoidable deviations. |
| Import prototype leaks into implementation scope | Medium | Keep import routes/buttons/API work out until explicitly approved in a later phase. |
| Existing tests rely on old route names/tabs | Medium | Update tests to new product model while preserving legacy route behavior only where needed. |

## Approved Decisions

- Legacy `/discover`, `/movies`, `/series`, and `/music` routes redirect into the new Services flow.
- The old setting for hiding Movies/Series/Music tabs is removed.
- Notifications are not implemented in this redesign phase and all dead notification affordances are omitted.
- Failed service status/version checks show `Offline`.

## Approval Gate

Implementation approved after the decisions above. First implementation batch: Tasks 1-5, because they establish visual tokens and navigation while preserving the navbar behavior.
