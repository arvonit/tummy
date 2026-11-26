# Plan 02: Search map, place card, and minimal Place screen

> **Status: built** on branch `feature/search-map`, branched from `feature/my-list`. Decisions
> made along the way are in the decision matrix below.

## Context

My Lists and the score engine are built (plan 01). This piece builds the Search tab that
decision 11 in `docs/decisions.md` describes: a full-screen map with a search bar pinned to the
bottom. Beli's map is the reference.

**Goal:** The Search tab shows a full-screen map of nearby food places from Apple Maps, with
score pins. Tapping a pin slides up a Liquid Glass card with the place's name, score, and
details, plus a Rank button. Tapping the card pushes a minimal Place screen. The search bar is a
Liquid Glass capsule above the tab bar, and submitting a query shows matching places on the map.

**Done when:**

- The app runs, and selecting a pin, searching, ranking, and pushing the Place screen all work.
- Existing tests still pass with the new `Restaurant` fields.

## Decision matrix

Decisions specific to the Search tab, from the grill-me session, review, and building. App-wide
decisions are in `docs/decisions.md`.

| # | Decision | Options considered | Chosen | Why | From |
| --- | --- | --- | --- | --- | --- |
| 1 | What the pins show | Ranked places + tappable Apple POIs; only ranked places; a sample "all places" set | All Apple food POIs with a stable fake community score. Places you've ranked show your score and a checkmark | Looks and works like Beli before any backend exists | Grill-me |
| 2 | Linking rankings to POIs | Real sample places matched by Apple ID; match by name; random "ranked" flags | Sample data becomes 38 real NYC places with Apple map item IDs and coordinates | Matching by Apple's ID is what the backend will do (decision 8) | Grill-me |
| 3 | Search bar and card | Floating glass bar and card; persistent sheet like Maps; tab bar bottom accessory | A floating glass capsule above the tab bar, replaced by a glass card when a pin is selected | Keeps the tab bar and avoids sheet-presentation workarounds | Grill-me |
| 4 | What searching does | Search the map; live autocomplete list; placeholder | Submitting runs `MKLocalSearch` in the visible area, shows the results as pins, and fits the map to them. Clearing goes back to nearby places | Smallest useful search. A results list and people search come later | Grill-me |
| 5 | Filter chips | Now; later | Later | Keeps this piece small | Grill-me |
| 6 | Map technology | SwiftUI `Map` hosted in UIKit; `MKMapView` | SwiftUI `Map` hosted by `SearchViewController` | About half the code (decision 18) | Grill-me |
| 7 | Card contents | Name, score, details; plus Look Around | Name, "Category · Cuisine", area, distance, score badge, and a Rank button | MapKit has no photos. Look Around can come later | Grill-me |
| 8 | Card tap and Rank | Placeholders; minimal Place screen | Card tap pushes a minimal SwiftUI Place screen. Rank presents a placeholder sheet until the rate flow exists | The user asked for the Place screen now | Grill-me |
| 9 | Starting location | Your location with an NYC fallback; always NYC | When-in-use location with a lower-Manhattan fallback, plus the system location button | Real-world use. Set the simulator to NYC to see the sample places | Grill-me |
| 10 | Pin style | Beli-style white capsule; glass capsule | White capsule: a bucket-colored circle with the category symbol, the score, and a checkmark badge if ranked | Glass pins get busy with dozens on screen | Grill-me |
| 11 | Apple's own POI labels | Show; hide | Hidden (`pointsOfInterest: .excludingAll`) | Our pins replace them, so there are no duplicates | Build |
| 12 | Fake community score | Random each launch; hashed from the Apple ID | FNV-1a hash of the ID mapped through the inverse normal CDF: mean 7.3, σ 1.1, clamped to 2.0–9.8 | Same score on every launch, with a believable spread. Swift's `hashValue` changes every launch | Build |
| 13 | POI category mapping | — | restaurant → Restaurants; nightlife, brewery, winery, distillery → Bars; bakery → Bakeries; cafe → Cafes | Apple has no dessert category, so dessert shops only show as Dessert once ranked (your ranking's category wins) | Build |
| 14 | Ranked places outside Apple's results | Only show Apple's results; always add ranked places | Always add your ranked places | Apple returns at most about 50 POIs per request, so your places could go missing | Build |
| 15 | Card and Place screen model | Pass a place and a ranking separately; one `PlaceSummary` | `PlaceSummary` (a `Place` plus an optional `ScoredRanking`) supplies the score, bucket, category, "kind", and area | The pin, card, and Place screen all agree, with no repeated logic | Build |
| 16 | Area shown | Apple's city; your saved neighborhood | Your saved neighborhood if ranked, otherwise Apple's city | "Lower East Side" says more than "New York" | Build |
| 17 | Dismissing the card | Tap empty map; swipe down; close button | Swipe the card down | Tapping empty map doesn't clear `Map`'s selection when pins are custom `Annotation`s | Build |
| 18 | Starting camera | `.userLocation(fallback:)`; a 2.5 km region around you | A 2.5 km region around your last known location, otherwise lower Manhattan | The system's user-location camera zooms out past the 0.08° limit, so no nearby places loaded | Build |
| 19 | When nearby places load | Every camera change; only when zoomed in | On first appearance, and when the camera stops while browsing with a span under 0.08° | Zoomed far out, Apple's handful of results looks random | Build |
| 20 | Ranking store | One per tab; shared | One `SampleRankingStore`, created by `TabBarController` and passed to both tabs | A change in one tab shows in the other | Build |
| 21 | UI checks | Xcode previews through the MCP; simulator | Simulator, kept running between changes | Previews took too long to render each time | Review |

## How the code should be written

The same rules as plan 01: simple and succinct, no third-party dependencies, self-documenting
names with comments only for the *why*, the Schreiber style for UIKit, and every newer Swift
concept explained in the summary at the end. Don't commit until the user says to.

## Steps

### 0. Branch

- `git switch -c feature/search-map` from `feature/my-list`, which isn't merged into `main`
  yet.
- Add the feature-branch rule to `CLAUDE.md`.

### 1. Sample data and model

- `SampleData/sample_rankings.json`: 38 real NYC places across all five categories, each with
  `mapItemID`, `latitude`, and `longitude` (looked up with `MKLocalSearch`), listed best first
  within each bucket.
- `Restaurant` gains `mapItemID`, `latitude`, `longitude`, and a computed `coordinate`. Doubles
  keep it `Hashable`, which `CLLocationCoordinate2D` isn't.
- `SampleData.swift` decodes the new fields. The `Restaurant(...)` calls in
  `ScoreCurveTests.swift` and the `RankingCellView` preview are updated.

### 2. Models

- `PlaceCategory`: `init?(_: MKPointOfInterestCategory)`, `singularTitle`, `symbolName`, and
  `mapFilter`. `mapFilter` is computed, because a stored static `MKPointOfInterestFilter` isn't
  `Sendable`.
- `ScoreCurve.bucket(for:)` gives community scores a pin color.
- `Models/Place.swift`: `Place`, from an `MKMapItem` or a `Ranking`, and `PlaceSummary`.
- `SampleData.communityScore(for:)`.

### 3. Store

`Stores/PlaceStore.swift`: the `PlaceStore` protocol (`places(in:)`, `search(_:in:)`, and
`mapItem(for:)`) and `MapKitPlaceStore`, built on `MKLocalPointsOfInterestRequest`,
`MKLocalSearch`, and `MKMapItemRequest`.

### 4. Views — `app/Tummy/Views/`

- `PlacePinView`, `SearchBarView` (`.glassEffect(.regular.interactive(), in: .capsule)`), and
  `PlaceCardView` (glass rounded rect).
- `SearchMapView`: `Map(position:selection:)` with tagged `Annotation`s, `onMapCameraChange`, and
  the card or search bar in `.safeAreaInset(edge: .bottom)`.
- `PlaceView`: a map header running under the navigation bar, a serif title, score, kind, area
  and distance, and glass Directions, Call, and Website buttons, filled in by `mapItem(for:)`.

### 5. UIKit host

- `SearchViewController` hosts `SearchMapView`, hides its navigation bar, pushes `PlaceView`, and
  presents the rate-flow placeholder at medium and large detents.
- `TabBarController` uses it for the Search tab, shares one ranking store, and starts on Search.
- `NSLocationWhenInUseUsageDescription`, added through the Xcode MCP's `AddInfoPlist`.

### 6. Docs

This plan, the build order in `docs/README.md`, and `PlaceStore` in `docs/architecture.md`.

## Verification

Done in the simulator, with its location set to lower Manhattan:

- Ranked and unranked pins load, and ranked ones have checkmarks.
- Selecting a pin grows it and shows the card. Swiping the card down brings back the search bar.
- Rank shows the placeholder sheet.
- The card pushes the Place screen, which loads Apple's phone number and website.
- Searching "pizza" fits the map to the results, and clearing returns to nearby places.
- My Lists shows the new places.
- Dark mode works.
- All 22 `ScoreCurveTests` pass.

## Out of scope

The rate flow, filter chips, a results list, people search, photos and Look Around, want-to-try
or bookmarks, and pin clustering.

## Implementation notes

- The My Lists fix in `d93aae4` (hiding a stuck top edge effect) doesn't apply here. The map
  hides its navigation bar, and on the Place screen the soft edge effect only fades the status
  bar area over the map header.
- Dense areas stack many pins on top of each other. Clustering, or capping how many nearby places
  show, is the natural next step.
- Rankings load once when the map first appears. When the rate flow exists, the map needs to
  reload them after a ranking changes.
- SourceKit in the editor shows "Cannot find type" errors across files in this project.
  `xcodebuild` and the Xcode MCP's `BuildProject` are the source of truth.
