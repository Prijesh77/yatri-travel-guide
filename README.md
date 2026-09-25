# Yatri — Kathmandu Valley travel guide

Yatri is a Flutter app for tourists and locals in Kathmandu, Lalitpur and
Bhaktapur. It suggests places and day plans that fit the conditions **right
now** (weather, air quality, time of day, opening hours, distance, festivals,
closures and bandhs) and explains how to get between them by local bus, taxi,
bike taxi or on foot.

Version 1 runs entirely on bundled JSON data plus the free Open-Meteo weather
API. There are no API keys and no backend.

## Features

| Screen | What it does |
| --- | --- |
| **Explore** (home) | Current valley weather and air quality, any active alerts, category filters, and a "Good for today" list ranked for current conditions. Each card gives a short reason, such as *"Indoor, good for a rainy afternoon · 1.2 km away"*. |
| **Place detail** | Photo placeholder, description, opening hours with open/closed status, entry fees for foreigners, SAARC and Nepali visitors, current suitability with every scoring reason, transport options from where you are, *Add to itinerary* and *Show on map*. |
| **Plan** | Pick a date, start time, time available, start point (GPS or presets such as Thamel or the airport), interests and travel style to get an ordered day plan. Stops show visit times and travel legs, and each leg expands to show all transport options. You can drag to reorder, remove (with undo), *Optimise order* and see the plan on the map. Stops that would be closed or run late are flagged. |
| **Map** | OpenStreetMap tiles via `flutter_map`, colour-coded markers for all ~60 places, category filter, your location, and the day's itinerary drawn as a numbered route. |
| **Preferences** | Interests, visitor type (sets which entry fee is shown) and travel style (budget, balanced or comfort). |

Offline behaviour:

- Places, routes and alerts are bundled and cached.
- The last weather result is saved and shown with an "Offline · saved 10:30" note.
- The itinerary and preferences are persisted.
- Recently viewed map tiles are cached by flutter_map's built-in tile cache (mobile and desktop).

## Running

Requirements: Flutter 3.47 or newer (Dart SDK ^3.13, see `pubspec.yaml`).

```bash
flutter pub get          # also generates lib/l10n/generated/*
flutter run              # Android / iOS device or emulator
flutter run -d chrome    # web
flutter test             # unit + widget tests
flutter analyze
```

Platform notes:

- **Android**: `INTERNET` and location permissions are declared in `android/app/src/main/AndroidManifest.xml`.
- **iOS**: `NSLocationWhenInUseUsageDescription` is set in `ios/Runner/Info.plist`.
- If location is denied, the app still works. Distances are hidden and the planner starts from a preset such as Thamel.

## Architecture

The code is organised by feature. Each feature has up to four layers:

```
lib/
  main.dart                 bootstrap: SharedPreferences -> ProviderScope
  app/                      MaterialApp, bottom-nav shell, cross-tab navigation state
  core/
    data/                   KeyValueStore (SharedPreferences / memory), JsonSource,
                            OfflineFirstJsonLoader (remote -> cache -> bundled)
    geo/                    GeoPoint + haversine, valley bounds
    time/                   Kathmandu time (UTC+05:45), DayPart, HH:mm helpers
    presentation/           l10n access + formatters (durations, NPR, reasons)
    providers/              clock, "now" ticker, key-value store
    theme/                  Material 3 theme, category / weather / transport styling
  l10n/                     app_en.arb (+ generated AppLocalizations)
  features/
    places/                 Place model, opening hours, repository, cards, detail screen
    weather/                Open-Meteo parser + repository (with cache), weather card
    alerts/                 festivals / closures / road closures / bandhs
    recommendations/        RecommendationEngine (scoring), providers
    transport/              RouteNetwork (routes.json), FareEstimator, options list
    itinerary/              ItineraryPlanner, controller (persisted), plan form + view
    map/                    map screen, tile provider
    location/               GPS service, start presets
    profile/                user preferences
    home/                   Explore screen
```

| Layer | Contents | Depends on |
| --- | --- | --- |
| `domain/` | Plain Dart models and logic: `RecommendationEngine`, `ItineraryPlanner`, `FareEstimator`, `OpeningHours`. No Flutter imports. | nothing |
| `data/` | Repositories behind interfaces (`PlacesRepository`, `RoutesRepository`, `AlertsRepository`, `WeatherRepository`, `LocationService`) | domain, core/data |
| `application/` | Riverpod providers and notifiers that wire repositories to domain logic | domain, data |
| `presentation/` | Widgets | application, domain |

**State management** uses Riverpod 3. The main providers:

- `rankedPlacesProvider` combines places, `currentContextProvider` (time, weather, location, interests, alerts) and the engine.
- `itineraryControllerProvider` (an `AsyncNotifier`) owns the day plan. It persists only the request and the ordered place ids, then re-times everything on load, so a saved plan always reflects the latest weather and data.
- Weather is not awaited. Rankings appear immediately and re-rank when weather arrives.

**Time**: opening hours, weather and plans use Nepal Time whatever the phone's
timezone, so someone planning from abroad sees correct "open now" information.
Kathmandu wall-clock times are stored in UTC-flagged `DateTime`s. See
`lib/core/time/kathmandu_time.dart`.

**Offline-first loading** (`OfflineFirstJsonLoader`) tries three sources in order:

1. A remote source, if configured. Successful results are cached.
2. The cached copy, if its `version` is at least the bundled `version`.
3. The bundled asset, which is always available.

A new app build with newer bundled data therefore wins over an old cache, and a
backend can push data newer than the app.

### Recommendation scoring

`lib/features/recommendations/domain/recommendation_engine.dart` is a pure
class. `score(place, context)` returns a `ScoredPlace` with a numeric score, an
open status and a list of `ScoreReason`s. Reasons are codes, not strings, and
the UI turns them into localised text. All weights live in `ScoringWeights`.

| Factor | Effect (default weights) |
| --- | --- |
| Popularity (1–5) | 5 points per level |
| Rain / high rain probability | indoor +18 (*"Indoor, good for a rainy afternoon"*), partly covered +5, outdoor −18 |
| Clouds / fog / rain at a viewpoint | −12 (*"Clouds may hide the views"*); clear skies +8 |
| Clear weather, outdoors | +6 |
| Air quality (US AQI) | AQI >150: outdoor −12, indoor +6; AQI 101–150: outdoor −4 |
| Heat ≥30 °C around midday | outdoor −6 |
| Best time of day (`bestTimes`) | +10 (sunrise at Nagarkot, evening aarati at Pashupati, …) |
| Meal times (food) | +8 at 07:00–09:30, 12:00–14:30 and 18:00–21:00 |
| After dark | outdoor nature or viewpoint −20, other outdoor −8 |
| Opening hours | closed today or closed now −100 (unavailable); opens within 1 h −6, later −25; closes before the visit ends −10, within 30 min −30 |
| Distance from the user | +10 nearby, dropping 0.9 per km to a minimum of −14 |
| Interests | primary category +12, secondary +6 |
| Alerts | closure of the place −100; festival −6 (crowds); road closure −10; bandh: walkable +8, otherwise up to −25 |

The home feed also runs `diversify()` so one category doesn't fill the top of
the list.

### Itinerary planner

`ItineraryPlanner.plan()` is greedy. From the current position and time it
picks the place with the best:

```
score at arrival time − 0.25 × travel minutes − 7 × earlier stops of the same category
```

Candidates must be open for the whole visit (waiting up to 30 min for opening
is allowed) and must finish before the end of the time available. The plan
includes at most one meal stop, or two if food is an interest.

- `schedule()` re-times a plan in a given order after an edit and adds warnings.
- `optimizeOrder()` shortens total travel with nearest neighbour plus 2-opt.

### Transport and fares

For each leg, `FareEstimator.optionsFor(from, to, time)` returns:

- **Walk**: up to 3 km, free.
- **Bike taxi and taxi**: base + per-km fare with a minimum, shown as a range. Taxis cost ×1.5 at night, and rush hours are slower.
- **Local bus**: the fastest direct route in `routes.json` with a stop within 1.2 km of each end, using the route's flat fare or the distance fare slabs. If no sample route matches, it gives a flagged generic estimate ("ask locally which bus to take"). Buses are unavailable outside service hours and during a bandh.

Road distance is estimated as straight-line distance × `roadDistanceFactor`.
`recommend(options, travelStyle)` picks the option used for itinerary timing.

## Updating the data

All data lives in `assets/data/`. After editing, **bump `version`** so cached
copies are replaced, then run `flutter test`. `test/features/data/bundled_data_test.dart`
checks ids, coordinates (must be inside the valley), categories, fees, times and
route references.

### `places.json`

```jsonc
{
  "id": "patan-museum",                 // unique, kebab-case; stored in saved plans
  "name": "Patan Museum",
  "city": "lalitpur",                   // kathmandu | lalitpur | bhaktapur
  "category": "heritage",               // heritage | temple | nature | food | shopping | viewpoint
  "secondaryCategories": [],            // count at half weight for interests / filters
  "lat": 27.6733, "lng": 85.3252,
  "visitMinutes": 90,                   // typical visit
  "entryFeeNpr": { "foreigner": 1000, "saarc": 250, "nepali": 100 },
  "openingHours": { "open": "10:30", "close": "17:30", "closedOn": ["tue"] },
                                        // or { "alwaysOpen": true }
  "setting": "indoor",                  // indoor | outdoor | mixed
  "bestTimes": ["afternoon"],           // earlyMorning | morning | afternoon | evening | night
  "popularity": 5,                      // 1-5
  "description": "…",                   // 40-300 characters
  "imageUrl": null,
  "i18n": { "ne": { "name": "पाटन संग्रहालय" } }   // optional translations
}
```

### `routes.json`

- `network`: road distance factor, max walk to a stop, rush hours and rush-hour speed factor.
- `modes`: speed and fare model for `walk`, `bikeTaxi`, `taxi` (with an optional `night` surcharge) and `bus` (service hours and distance `fareSlabs`).
- `stops`: `{ "id", "name", "lat", "lng" }`.
- `routes`: `{ "id", "name", "vehicle", "stops": [stop ids in order], "frequencyMinutes", "flatFare"? }`. Routes work in both directions.

The format was kept close to a simplified GTFS (stops plus ordered stop lists),
so real data can be generated into it. You can also replace
`JsonRoutesRepository` with an API-backed `RoutesRepository`.

### `alerts.json`

Empty in v1. Example entries:

```json
{
  "version": 2,
  "alerts": [
    {
      "id": "indra-jatra-2026",
      "type": "festival",
      "title": "Indra Jatra",
      "description": "Chariot processions around Basantapur; expect crowds and road diversions.",
      "start": "2026-09-25T10:00",
      "end": "2026-09-25T20:00",
      "placeIds": ["kathmandu-durbar-square", "kumari-ghar"]
    },
    {
      "id": "bandh-example",
      "type": "bandh",
      "title": "Valley-wide bandh",
      "start": "2026-10-02T06:00",
      "end": "2026-10-02T18:00"
    }
  ]
}
```

- `type` is one of `festival | closure | roadClosure | bandh`.
- Times are Kathmandu local time.
- `cities` and `placeIds` limit the scope. If both are omitted, the alert covers the whole valley.

## Extending

- **Nepali language**:
  - Copy `lib/l10n/app_en.arb` to `app_ne.arb`, translate it and run `flutter gen-l10n` (or `flutter pub get`). All UI text, including recommendation reasons, goes through `AppLocalizations`.
  - Place names are already read from `i18n.ne.name` when the locale is Nepali. Add the matching descriptions the same way.
- **Backend**: pass a `remote: HttpJsonSource(Uri.parse(...))` to the `OfflineFirstJsonLoader` in the repository providers (`places_providers.dart`, `transport_providers.dart`, `alerts_providers.dart`), or implement the repository interfaces directly. The domain and UI don't change.
- **Live traffic and event alerts**:
  - Implement `AlertsRepository` against a live feed. The engine and fare estimator already react to `ConditionAlert`s.
  - Traffic can feed `NetworkSettings.rushHourSpeedFactor` or a per-leg speed.
- **Real road routing**: swap the straight-line polyline and `roadDistanceFactor` for an OSRM/GraphHopper call behind a new `RoutingService`.
- **Photos**: fill `imageUrl` and replace `_PhotoPlaceholder` in `place_detail_screen.dart`.

## Tests

The suite has 90 tests:

| File | Covers |
| --- | --- |
| `test/features/recommendations/recommendation_engine_test.dart` | weather, AQI, opening hours, time of day, distance, interests, alerts, diversity |
| `test/features/itinerary/itinerary_planner_test.dart` | time budget, opening hours, interests, rain, meals, re-scheduling after remove/reorder, waiting for opening, warnings, order optimisation |
| `test/features/transport/fare_estimator_test.dart` | taxi/bike fares, minimum fare, night and rush hour, bus slabs, route matching in both directions, flat fares, fallback estimates, service hours, bandh, travel-style choice |
| `test/features/weather/open_meteo_test.dart` | parser (recorded fixtures), WMO codes, offline cache fallback |
| `test/features/data/` | offline-first loader and validation of the bundled JSON |
| `test/widget/app_flow_test.dart` | end-to-end UI with fake weather and location: home ranking in rain, place detail → add to plan, plan → remove → undo |

## Known limitations (v1)

- Entry fees, opening hours, bus routes and fares are approximate sample data. The app says so in the UI. Check them before relying on them.
- Bus routing only uses direct routes (no transfers) from a small sample network.
- The map draws straight lines between stops, not road routes.
- Photos are placeholders.
