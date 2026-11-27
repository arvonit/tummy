# Plan 01: Repo reorg + My Lists and score engine

> **Status: built** on branch `feature/my-list`. Decisions made along the way are in the
> decision matrix below.

## Context

The design session settled the app-wide decisions (see `docs/decisions.md`). This is the first
build piece. The repo root is now lowercase `tummy/` and the template-conversion baseline is
committed. The project is still a bare template: `Tummy/` plus `Tummy.xcodeproj` in Xcode 27's
JSON `project.xcproj` format, iOS 27.2, already set to default `MainActor` isolation.

**Goal:** The app launches into a 4-tab shell whose My Lists tab shows about 25 sample restaurants,
ranked, scored on the bell curve, and filterable by bucket. Swipe-to-delete recomputes scores
live. Everything uses static data, with no network.

**Done when:**

- `ScoreCurve` unit tests pass.
- The SwiftUI cell views render in `#Preview`.
- The app runs in the simulator and the My Lists screen behaves as described below.

## Decision matrix

Decisions specific to My Lists, from the grill-me session and later review. App-wide decisions are
in `docs/decisions.md`.

| # | Decision | Options considered | Chosen | Why | From |
| --- | --- | --- | --- | --- | --- |
| 1 | First UI piece | My Lists + score engine; comparison flow; row cell only; map search | My Lists + score engine | Proves the bell curve first and sets the list and cell patterns | Grill-me |
| 2 | Row layout | Score circle on the right; big score on the left; plus a debug histogram | Rank, name over "cuisine · neighborhood", score circle on the right | Beli-like and easy to scan | Grill-me |
| 3 | Score badge | Solid bucket-colored circle with white text; light gray circle with bucket-colored text | Gray circle, bucket-colored text | Matches Beli | Review |
| 4 | Rank number position | Right-aligned in a fixed column; hug the leading edge | Hug the leading edge, with room for two digits | Balances the row's left and right margins and keeps names aligned | Review |
| 5 | List style | Inset grouped; plain | Plain, full width | Uses the whole screen width, like Messages | Review |
| 6 | What the filter filters | Bucket (Like/Fine/Dislike); category | Category, no bucket filter | Categories are separate lists, so they're the natural way to browse | Review |
| 7 | Filter control | Segmented control; scrolling chips; pull-down menu | Scrolling chips in SwiftUI, hosted with `UIHostingController` | Six options don't fit a segmented control. A simple control, so SwiftUI | Review |
| 8 | Chip style | Solid fills; Liquid Glass | Liquid Glass; selected chip gets a translucent accent tint | Matches system styling | Review |
| 9 | Title | Inline title; large title | Large title that collapses on scroll | Standard for top-level screens | Review |
| 10 | Chip placement | Below the bar with the list stopping at them; floating over the list; part of the bar's bottom edge | Part of the bar's bottom edge (`additionalSafeAreaInsets` plus `UIScrollEdgeElementContainerInteraction`) | Matches GitHub's inbox. The list's insets and the bar's effect treat the chips as part of the bar | Review |
| 11 | Top edge effect | Automatic (renders soft on iOS 27.2); hard | Hard | A solid bar with a dividing line, like GitHub | Review |
| 12 | Rank numbers | Stored overall and bucket ranks; number the visible rows | Number the visible rows, best first | Works for any filter with no extra model fields | Build |
| 13 | Equal scores in "All" | Leave order to the sort; break ties by name | Break ties by name | Deterministic order across reloads | Review |
| 14 | Tapping a row | Tap and deselect; not selectable | Not selectable until the detail screen exists (**superseded** by plan 03: rows push the Place screen) | Same result in less code | Build |
| 15 | Model conformances | `Codable` everywhere now; only what's needed | Only `Bucket` and `PlaceCategory`, and only `Decodable` | Nothing encodes yet. Add `Codable` with the backend | Build |
| 16 | Screen and tab name | My List; My Lists | My Lists (`MyListsViewController`) | The screen holds a separate ranked list per category | Review |

## How the code should be written

- **Simple and succinct.** Prefer plain Swift and UIKit/SwiftUI APIs over extra libraries or
  clever abstractions. No third-party dependencies for this piece.
- **The user's Swift knowledge dates from Stanford CS193p (2020).** The user knows of, but
  isn't fluent in, `@MainActor` (never used), `nonisolated`, `Sendable`,
  `UIHostingConfiguration`, `#Preview`, Swift Testing's `@Test`/`#expect`, and diffable data
  sources. These are fine to use where they fit. Avoid other newer concepts unless they're
  clearly the best tool. Every newer concept that ends up in the code gets a high-level
  explanation in the summary at the end of the build, so the code can be reviewed with
  confidence.
- **Self-documenting code first.** Use clear names and small functions. Add comments only where
  the *why* isn't obvious, such as the score math.
- **Follow the Schreiber codebase** (`~/Development/Archive/Schreiber`) as the style reference:
  - programmatic UIKit
  - `configViewController()`, `configCollectionView()`, and `configDataSource()` called from
    `viewDidLoad()`
  - `ViewHelper` cell-registration factories
  - SwiftUI cell content
  - `#Preview` on UIKit screens (now passed directly, with no wrapper types)
- **Don't commit anything** until the user says to.
- Follow the user's global CLAUDE.md conventions: 100-column lines, acronyms in uppercase, no
  banner comments, and no period on one-sentence comments.

## Steps

### 1. Reorg

Before starting, ask the user to close the project in Xcode.

- Run `git mv Tummy.xcodeproj app/Tummy.xcodeproj` and `git mv Tummy app/Tummy`. Paths in
  `project.xcproj` are relative to the project, so they stay valid.
- Delete `app/Tummy/ViewController.swift`. It's the empty template placeholder, and the root is
  now `TabBarController`.
- Add a root `.gitignore` for `.DS_Store`, `xcuserdata/`, `tmp/`, `DerivedData/`, and `build/`.
  Run `git rm --cached` on the tracked `UserInterfaceState.xcuserstate` and `.DS_Store` files.
- Add one-line placeholder READMEs at `supabase/README.md` and `services/README.md`.

### 2. Project settings (hand-edit `app/Tummy.xcodeproj/project.xcproj`)

- Change `SWIFT_VERSION` → `6.0`.
- Add a `TummyTests` unit-test target in `app/TummyTests/`, which is Xcode's `<Target>Tests`
  convention, next to `app/Tummy/` rather than inside it. Model the entry on the existing
  target:
  - a synced `"kind": "folder"` entry
  - product type `unit-test-bundle`
  - a dependency on `Tummy`
  - `TEST_HOST` and `BUNDLE_LOADER` set to the app
- **Risk:** this JSON format is new. If `xcodebuild -list` rejects the edit, revert it and ask
  the user to add the target in Xcode with File ▸ New ▸ Target ▸ Unit Testing Bundle (Swift
  Testing).
- The app's source folder is synced, so new files under `app/Tummy/` are picked up with no
  further project edits.

### 3. Models — `app/Tummy/Models/`

- `Bucket`: `like | fine | dislike`, with a display title and color (green, orange, or red).
- `Restaurant`: `id`, `name`, `cuisine`, and `neighborhood`.
- `Ranking`: `id`, `restaurant`, `bucket`, and `position`, where 0 is the worst place in its
  bucket.
- `ScoredRanking`: a `Ranking` plus its derived `score` and `overallRank`. This is what the UI
  shows.

All of these are plain value structs (`Codable`, `Hashable`, and `Sendable`).

### 4. Score engine — `app/Tummy/Scoring/ScoreCurve.swift`

This implements the math in `docs/rating-system.md`.

- Bucket constants: like 6.5–10, fine 4–6.5, and dislike 0–4. μ is the midpoint and σ is
  range/4.
- `normalCDF(x) = 0.5 * erfc(-x / √2)`. `inverseNormalCDF(p)` uses Acklam's approximation.
- `score(position:count:bucket:)` uses the Hazen position `p = (i + 0.5) / n` and the
  truncated-normal quantile.
- `scored(_ rankings:) -> [ScoredRanking]` sorts by score, highest first, and assigns
  `overallRank` from 1 to n.

### 5. Tests — `app/TummyTests/ScoreCurveTests.swift` (Swift Testing)

- `inverseNormalCDF` round-trips with `normalCDF`, and the known quantile 0.975 → 1.95996.
- With `count == 1`, each bucket's score is μ.
- Scores stay within `[lo, hi)` and increase strictly with position.
- Scores are symmetric around μ.
- Worked example: in the like bucket with `n = 10`, the scores are about 9.5, 8.4, and 7.0.
- Distribution: with `n = 100`, most scores fall within μ ± σ.

### 6. Sample data — `app/Tummy/SampleData/`

- `sample_rankings.json`: 25 invented restaurants (14 like, 7 fine, and 4 dislike) with
  varied cuisines and neighborhoods.
- `SampleData.swift` decodes the JSON from the app bundle. Previews use it too.

### 7. Data store — `app/Tummy/Stores/RankingStore.swift`

- `RankingStore` protocol: `rankings() async throws -> [Ranking]` and
  `delete(_ id:) async throws`. Screens only ever talk to this protocol, so sample data,
  Supabase, and the future API can swap in with no UI changes.
- `SampleRankingStore` keeps rankings in memory. `delete` closes the position gap within the
  bucket.

### 8. Cell views (SwiftUI) — `app/Tummy/Views/`

- `ScoreBadgeView`: a circle in the bucket color with the score at one decimal place in
  monospaced digits.
- `RankingCellView`: the rank number, the name in bold, "cuisine · neighborhood" in a secondary
  style, and the badge trailing.
- `#Preview`s for every bucket, a long name, and accessibility XXL text.

### 9. My Lists screen — `app/Tummy/ViewControllers/MyListsViewController.swift`

- `configViewController()`: large title "My Lists", with a segmented control
  (All / Like / Fine / Dislike) as the nav title view.
- `configCollectionView()`: a `.plain` list layout so rows span the full width like Messages,
  plus a trailing destructive Delete swipe action.
- `configDataSource()`: a diffable data source keyed by `Ranking.ID`. Cells come from
  `ViewHelper.makeRankingCell()`, which hosts `RankingCellView` through
  `UIHostingConfiguration`.
- Data flow: load from the store, run `ScoreCurve.scored`, filter by the selected segment, and
  apply the snapshot.
- Delete: remove the place, rescore, and reconfigure the remaining items so their badges animate
  to the new scores.
- Rank shown: the overall rank in All, and the within-bucket rank (best = 1) when a bucket is
  filtered.
- Tapping a row only deselects it for now.

### 10. App shell

- `app/Tummy/ViewControllers/TabBarController.swift` has four tabs, each a
  `UINavigationController`:
  - Feed (`list.bullet.rectangle`)
  - My Lists (`list.number`)
  - Search (`map`)
  - Profile (`person.crop.circle`)
- Tabs that aren't built yet show a `PlaceholderViewController` ("Coming soon").
- My Lists starts selected while it's under development.
- `SceneDelegate` sets the tab bar as the root view controller. Trim the template comments.
- Add a `#Preview` for `MyListsViewController` that returns the view controller directly,
  wrapped in a `UINavigationController` so the title and segmented control show. Since Xcode 15
  (iOS 17+), `#Preview` accepts a `UIView` or `UIViewController` directly, so Schreiber's
  `ViewPreview` and `ViewControllerPreview` wrappers (written before that) aren't needed.

### 11. Docs

- Save this plan as `docs/plans/01-my-list.md`, replacing the old file.
- Update `docs/architecture.md` and `docs/decisions.md` with these changes:
  - "Repository" → "Store" (`RankingStore`)
  - the full-width `.plain` list
  - the `app/TummyTests` location
  - `configVC()` → `configViewController()`
- Update `CLAUDE.md` the same way: its "repository protocols" line and the `configVC()` name.

## Verification

- `xcodebuild -list -project app/Tummy.xcodeproj` loads, which confirms the reorg and the project
  edit.
- Tests pass, with build output in the scratchpad or `tmp/`:
  `xcodebuild test -project app/Tummy.xcodeproj -scheme Tummy -destination 'platform=iOS Simulator,name=iPhone 18 Pro'`
- Attach the iOS Simulator panel first, then build and launch on an iPhone 18 Pro.
- Take screenshots of All, each filter, the list after one swipe-delete (scores shift), and
  dark mode.
- Check the scores against the worked example in `docs/rating-system.md`.
- End with a short summary of each newer Swift concept used, written for review.

## Out of scope

The comparison flow, adding places, the detail screen, persistence, and networking.

## Implementation notes

- The test target's product type is `bundle.unit-test` in the JSON project file. A shared
  `Tummy` scheme (`app/Tummy.xcodeproj/xcshareddata/xcschemes/Tummy.xcscheme`) adds the test
  action, which Xcode's auto-generated schemes don't have.
- The hosted chips need `safeAreaRegions = []`. Otherwise they respect the safe area they add
  themselves, push their content down, and grow in a loop.
- The hard top edge effect could stay on after scrolling back to the top, which blurred the
  large title. `scrollViewDidScroll` now hides the effect whenever the list rests at its top.
- When the list is pulled down past its top, the large title moves down with it but the chips
  (pinned by the safe area) don't. `scrollViewDidScroll` shifts the chips by the pull distance.
