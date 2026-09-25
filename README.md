# Yatri — Kathmandu Valley travel guide

Yatri is a Flutter app for tourists and locals in Kathmandu, Lalitpur and
Bhaktapur. It suggests places and day plans that fit the conditions **right
now** (weather, air quality, time of day, opening hours, distance, festivals,
closures and bandhs) and explains how to get between them by local bus, taxi,
bike taxi or on foot.

The app runs on bundled JSON data, the free Open-Meteo weather API and,
optionally, Google's Gemini API (free tier) for AI itineraries. There is no
backend yet: crowdsourced reports are stored on the device.

## Screens

The UI follows the Phase 1 wireframes ([`docs/Yatri_Wireframes.pdf`](docs/Yatri_Wireframes.pdf), 11 screens).
The bottom navigation has five tabs: Home, Transit, Alerts, Plan and Profile.

| # | Screen | What it does |
| --- | --- | --- |
| 01 | **Home** | Search, *Plan a trip with AI* banner, category tiles, and "Right now" chips (disruptions, events today). Below them: valley weather and air quality, and the "Good for today" list ranked for current conditions, with a reason on each card (*"Indoor, good for a rainy afternoon · 1.2 km away"*). |
| 02 | **Transport – Find your route** | From/to (my location, hubs, places or any of 140 bus stops). Shows up to 3 bus options with route, boarding stop and walk, frequency (where published), total time and official fare, including journeys with one change. Routes serving the same stops are grouped ("SAJ-01 / SAJ-02"). Each option is tagged *Verified 2026* or *verify*, and expands into step-by-step legs and a map. Taxi, bike taxi and walking appear under "Other ways", and a warning shows if a reported disruption is on the way. |
| 03 | **Stays** | 18 real hotels, guesthouses and hostels, with filters by city and price band and sorted by distance. The detail page has transport options, map, save and "Route here". Price bands are approximate; no ratings are invented. |
| 04 | **Live conditions** | Disruptions (road closed, heavy traffic, bandh, place closed) and events (jatras), from the curated `alerts.json` plus community reports. You can *Report* one, confirm it ("Still there", once per device) or remove your own. Reports expire automatically, and "Load sample reports" fills an empty screen for demos. |
| 05 | **Plan with AI** | Budget (Budget / Mid-range / Comfort), interests (Culture, Food, Nature, Views, Shopping), and an optional date, start time, hours and start point, then *Generate itinerary*. The result is a timeline: *"09:00 · Depart via SAJ-03"* tagged **rerouted** when a reported closure is on the way, and *"10:30 · Patan Durbar Square"* tagged **event** when a jatra is nearby. The AI's tip and suitability reasons appear under each stop. Stops can be reordered, removed (with undo), optimised and shown on the map. |
| 06 | **Fare check** | Pick from/to and a mode (bus, microbus, tempo, taxi, bike taxi). Shows the crowdsourced low–typical–high range with a bar, the number of reports, and the official reference: the April 2026 fare slab, or the taxi meter at Rs 58 + Rs 12 per 200 m. *Submit a fare report* adds your fare. |
| 07 | **Profile** | Guest user ("Sign in to sync" is coming soon), saved places and stays, language (English; Nepali is prepared), notifications toggle, travel preferences, and *About the data*. |
| 08–11 | **Education, Fitness, Adventure, Healthcare** | Planned categories: wireframe-level placeholder screens reached from the grey Home tiles. |
| – | **Place detail, Map, Search** | Place page (hours, fees by visitor type, suitability with every reason, getting there, save, route here, add to plan). Full-screen map with places, alert areas, the day's plan or a bus journey. Global search over places, stays, stops and routes. |

Offline behaviour:

- Places, routes, stays and alerts are bundled and cached.
- The last weather result is saved and shown with an "Offline · saved 10:30" note.
- The plan (including AI notes), preferences, saved items and community reports are stored on the device.
- Without a connection or API key, *Generate itinerary* uses the on-device planner.
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

### Turning on AI planning (free)

*Plan with AI* uses Google's Gemini API free tier, which needs no card.

1. Sign in at [Google AI Studio](https://aistudio.google.com) and create an API key.
2. Pass it at build time. Never commit it.
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your-key
   # optional: --dart-define=GEMINI_MODEL=gemini-3.1-flash-lite   (default)
   ```

Without a key the app works the same, but plans come from the on-device
planner, and the Plan screen says so. Flash-Lite has the most generous
free-tier quota. Google adjusts free quotas over time, so check your limits in
AI Studio. On the free tier Google may use prompts to improve its products.
Yatri sends only the day's conditions, your preferences and place data, with
the start point rounded to about 1 km.

A key compiled into an app can be extracted. For a public release, move the call
behind a small backend (a Cloud Function, for example) that holds the key.
`AiItineraryService` is the only class that would change.

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
    home/                   Home (wireframe 01)
    transport/              RouteNetwork, JourneyPlanner (transfers), FareEstimator,
                            fare reports + stats; Transit and Fare check screens
    stays/                  stays.json, Stays list + detail
    alerts/                 ConditionAlert (location-aware), official + community
                            reports repository; Live conditions + Report sheet
    itinerary/              ItineraryPlanner, Gemini client, AI plan prompt/parser,
                            AiItineraryService, controller; Plan with AI timeline
    recommendations/        RecommendationEngine (scoring), providers
    places/                 Place model, opening hours, cards, detail screen
    weather/                Open-Meteo parser + repository (with cache), weather card
    profile/                preferences, saved items; Profile screen
    planned/                Education / Fitness / Adventure / Healthcare placeholders
    search/                 global search
    map/                    map screen, tile provider
    location/               GPS service, start presets, location picker
tool/import_transport.py    data pack (xlsx) -> assets/data/routes.json
data_sources/               the transport data pack + stop_coordinates.csv
```

| Layer | Contents | Depends on |
| --- | --- | --- |
| `domain/` | Plain Dart models and logic: `RecommendationEngine`, `ItineraryPlanner`, `FareEstimator`, `OpeningHours`. No Flutter imports. | nothing |
| `data/` | Repositories behind interfaces (`PlacesRepository`, `RoutesRepository`, `StaysRepository`, `AlertsRepository`, `ReportsRepository`, `FareReportsRepository`, `WeatherRepository`, `LocationService`, `AiItineraryService`) | domain, core/data |
| `application/` | Riverpod providers and notifiers that wire repositories to domain logic | domain, data |
| `presentation/` | Widgets | application, domain |

**State management** uses Riverpod 3. The main providers:

- `rankedPlacesProvider` combines places, `currentContextProvider` (time, weather, location, interests, alerts) and the engine.
- `itineraryControllerProvider` (an `AsyncNotifier`) owns the day plan. It persists only the request, the ordered place ids and any AI notes, then re-times everything on load, so a saved plan always reflects the latest weather, alerts and data.
- `alertsProvider` merges official alerts with `communityReportsProvider`. Recommendations, transport and plans all react to both.
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
| Alerts (by place, city or location + radius) | closure of the place −100; event nearby +4 (*"… nearby – lively, expect crowds"*); road closure −10, heavy traffic −5; bandh: walkable +8, otherwise up to −25 |

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
- **Advisories**: if an active road closure, traffic jam or bandh with a location lies on a leg, the leg gets +10 to 15 min and is tagged *rerouted* (*"Avoids Road closed – Naxal"*). Events near a stop during the visit tag it *event*.

### AI planning (Gemini)

`GeminiItineraryService` keeps the model grounded:

1. The engine scores every place at the start and middle of the time window. It keeps the 20 best that are open then and not closed by an alert.
2. The model gets those candidates (hours, fee for your visitor type, distance, suitability and reasons), the day's forecast and AQI, active alerts, budget and interests. The JSON response schema restricts `placeId` to the candidate ids, so it cannot invent places.
3. The answer is validated: unknown or repeated ids are dropped. The plan is then timed on device with `ItineraryPlanner.schedule()`, which adds transport legs, reroutes and warnings. Stops that would be closed, and trailing stops that overrun, are removed.
4. Any failure (offline, quota, bad JSON) falls back to the on-device planner. The plan shows *"AI unavailable right now – used the built-in planner"*.

### Transport, journeys and fares

`JourneyPlanner.plan(from, to, time)` searches the bus network (25 routes, 140
stops from the data pack):

- **Getting on and off**: you walk to any stop within 1.5 km, or the nearest stops within 2.5 km if none is closer. You can then ride directly, or change once at the same stop or one within 400 m.
- **Timing**: ride time comes from the distance along the route and bus speed, and is slower in rush hour. Waiting time is half the published frequency, or 10 min if none is published.
- **Service hours**: routes run only in their hours. Night e-buses SAJ-N1/N2 run 20:00–23:00, and the last Nagarkot bus leaves at 17:30.
- **Fares**: each ride is charged at the **April 2026 slab** (Rs 24 / 33 / 39 / 44 / 50 for ≤5 / 10 / 15 / 20 / 20+ km).
- **Ranking**: verified Sajha routes rank first. The other statuses (announced, OSM, reported, local, historical) get a small ranking penalty and a *verify* tag.

`FareEstimator.optionsFor(from, to, time)` adds walking (up to 3 km), a
**metered taxi** (Rs 58 flag-down + Rs 12 per 200 m, with up to +30% for
negotiated fares and a night surcharge) and a **bike taxi** estimate.
`recommend(options, travelStyle)` picks the option used for itinerary timing.

Fare reports are summarised by `FareStats`: the 10th percentile, median and
90th percentile, so one outlier doesn't stretch the range.

## Updating the data

All data lives in `assets/data/`. After editing, **bump `version`** so cached
copies are replaced, then run `flutter test`. `test/features/data/bundled_data_test.dart`
checks the JSON files, including:

- unique ids
- coordinates inside the valley
- categories, fees and times
- route references and hubs
- spacing between stops on verified routes (this catches a misplaced stop)

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

### `routes.json` is generated – edit the data pack instead

`routes.json` is built from the transport data pack with a stdlib-only Python
script:

```bash
python3 tool/import_transport.py            # reads data_sources/, writes assets/data/routes.json
```

- **`data_sources/Yatri_Transport_Data.xlsx`** is the data pack. The importer reads:
  - `Bus_Routes`: ordered `stops_in_order`, status, vehicle, hours/frequency, source
  - `Hubs`
  - `Fares`: the April 2026 slabs and taxi meter
  - `Taxi_RideHailing`

  To add or fix a route, edit the sheet and rerun the script.
- **`data_sources/stop_coordinates.csv`**: the sheet has no stop coordinates, so they live here (`stop_name,lat,lng,accuracy`).
  - `approx` means placed within a few hundred metres.
  - `rough` means placed to within 1–2 km. The app tags journeys that use these stops.
  - Stops without a row are dropped from their route, and the script lists them. Stops outside the valley (Banepa, Panauti, Dhulikhel, Nala, Tathali) are dropped, so BKT-03/04 end at Sanga and BKT-09 is skipped.
  - To improve accuracy, pull `highway=bus_stop` nodes from OpenStreetMap (Overpass) and update the CSV.
- **Spelling variants** are merged with `ALIASES` in the script (e.g. *Kaushaltar* → *Kausaltar*).
- **Version**: the script bumps `version` automatically, so installed apps replace their cached copy.

Route `status` values are `verified`, `announced`, `osm`, `reported`,
`local` and `historical`; the app shows them on every route option. The
format is a simplified GTFS (stops plus ordered stop lists), so a real GTFS
feed or an API-backed `RoutesRepository` can replace it.

### `stays.json`

`{ "id", "name", "type" (heritage | boutique | hotel | resort | guesthouse | hostel), "city", "area", "lat", "lng", "priceBand" (budget | mid | upscale | luxury), "description" }`. `priceBands` at the top of the file maps each band to an approximate NPR range per night.

### `alerts.json` (curated alerts)

Empty by default: users add community reports in the app, and "Load sample
reports" adds demo ones. Curated entries look like this:

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
      "id": "maitighar-closure",
      "type": "roadClosure",
      "title": "Road closed – Maitighar",
      "start": "2026-10-02T06:00",
      "end": "2026-10-02T18:00",
      "location": { "lat": 27.694, "lng": 85.322, "radiusKm": 0.5, "label": "Maitighar" }
    }
  ]
}
```

- `type` is one of `festival | closure | roadClosure | traffic | bandh`.
- Times are Kathmandu local time.
- `placeIds`, `cities` and `location` (with `radiusKm`) limit the scope. If none is given, the alert covers the whole valley.
- A `location` also lets the planner reroute legs that pass through the area.

## Extending

- **Nepali language**:
  - Copy `lib/l10n/app_en.arb` to `app_ne.arb`, translate it and run `flutter gen-l10n` (or `flutter pub get`). All UI text, including recommendation reasons, goes through `AppLocalizations`.
  - Place names are already read from `i18n.ne.name` when the locale is Nepali. Add the matching descriptions the same way.
- **Backend**: pass a `remote: HttpJsonSource(Uri.parse(...))` to the `OfflineFirstJsonLoader` in the repository providers (`places_providers.dart`, `transport_providers.dart`, `stays_providers.dart`, `alerts_providers.dart`), or implement the repository interfaces directly. The domain and UI don't change.
- **Shared crowdsourcing**: implement `ReportsRepository` and `FareReportsRepository` against the backend (Firebase or Supabase, for example) to share reports and confirms between users. The screens already use these interfaces.
- **Live traffic and event alerts**:
  - Implement `AlertsRepository` against a live feed. The engine, journey planner and itinerary advisories already react to `ConditionAlert`s.
  - Traffic can feed `NetworkSettings.rushHourSpeedFactor` or a per-leg speed.
- **Timetables**: add `frequencyMinutes` or `serviceHours` per route in the data pack. Real departure times would allow "Next in 6 min" instead of "Every ~10 min".
- **Real road routing**: swap the straight-line polyline and `roadDistanceFactor` for an OSRM/GraphHopper call behind a new `RoutingService`.
- **Photos**: fill `imageUrl` and replace `_PhotoPlaceholder` in `place_detail_screen.dart`.

## Tests

Run `flutter test`. GitHub Actions runs it on every pull request.

| File | Covers |
| --- | --- |
| `test/features/recommendations/recommendation_engine_test.dart` | weather, AQI, opening hours, time of day, distance, interests, alerts, diversity |
| `test/features/itinerary/itinerary_planner_test.dart` | time budget, opening hours, interests, rain, meals, re-scheduling after remove/reorder, waiting for opening, warnings, order optimisation, rerouting and event tags |
| `test/features/itinerary/ai_planner_test.dart` | Gemini request format (endpoint, key header, JSON schema with the candidate-id enum), API errors, parsing, candidate selection, dropping closed stops, controller fallback, notes kept after edits |
| `test/features/transport/journey_planner_test.dart` | direct rides and transfers on a synthetic network; service hours, rush hour, route-status ranking, grouping; real-data checks (Thamel → Koteshwor, Airport → Patan, Thamel → Nagarkot) |
| `test/features/transport/fare_estimator_test.dart` | taxi meter (Rs 58 + Rs 12/200 m), bike fares, night and rush hour, April 2026 slabs, bus journeys, estimates, service hours, bandh, travel-style choice |
| `test/features/transport/fare_reports_test.dart` | fare statistics (percentiles, outliers), trip matching both ways, samples |
| `test/features/alerts/community_reports_test.dart` | reporting, one confirm per device, expiry, samples, location-aware scope, closures on a path |
| `test/features/weather/open_meteo_test.dart` | parser (recorded fixtures), WMO codes, offline cache fallback |
| `test/features/data/` | offline-first loader; validation of places, routes, hubs, stays and alerts JSON |
| `test/widget/app_flow_test.dart` | Home (wireframe tiles, rain ranking), planned categories, place → plan, Plan with AI off → remove/undo, Transit to a hub, Live conditions (samples, confirm, Home counts), Fare check |

## Known limitations

- **Data accuracy**:
  - Entry fees, opening hours and stay price bands are approximate, and the UI says so.
  - Only the 8 Sajha Yatayat 2026 routes are verified. The rest of the data pack is marked *verify*.
  - Stop coordinates were placed by hand, and some are *rough*.
- **Transit**:
  - No published timetables, so the app shows "Every ~N min" where a frequency is known rather than "Next in 6 min".
  - Microbus and tempo routes aren't in public data yet (see the data pack's `Gaps_To_Collect`).
- **Crowd data**: reports and fare reports stay on the device until a backend exists.
- **AI planning**: needs a free Gemini key (see above) and is best-effort. The on-device planner is the fallback.
- **Map and media**: the map draws straight lines between stops rather than road geometry, and photos are placeholders.
