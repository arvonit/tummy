# Plan 03: Rate flow, Feed, and Profile

> **Status: built** on branch `feature/feed-profile-rating`, branched from `main`. Decisions
> made along the way are in the decision matrix below.

## Context

My Lists (plan 01) and the Search map with a minimal Place screen (plan 02) are built. Rank
buttons on the map card and Place screen still open a placeholder, and the Feed and Profile tabs
are placeholders. This plan covers build-order steps 3, 4, 6, and 7 in `docs/README.md`:

- **Rate flow.** One sheet for category, bucket, and visit details. Rank starts the binary
  comparisons, and a result step shows the new score.
- **Feed.** Your visits and those of about 6 sample friends, newest first.
- **Profile.** Yours, and friends' as read-only.

Beli's screenshots are the visual reference. The rate flow comes first, because the Feed and
Profile show what it creates.

**Done when:**

- Rating a new place, revisiting one, and re-ranking one all work from the map card, the Place
  screen, and Feed cells, and the change shows in every tab without a relaunch.
- The Feed, your Profile, and a friend's Profile show the sample data and your new visits.
- New unit tests and the existing `ScoreCurveTests` pass.

## Decision matrix

| # | Decision | Options considered | Chosen | Why | From |
| --- | --- | --- | --- | --- | --- |
| 1 | Plan split | One plan; three plans; screens first | One plan, built in this order: rate flow, Feed, Profile | The Feed and Profile show what the rate flow creates | Grill-me |
| 2 | Rate flow order | Beli order; docs order; details optional | Beli order: one sheet with category, bucket, and details. Rank starts the comparisons | Details get written while the visit is fresh | Grill-me |
| 3 | Detail rows | Decision 6 only; companions; stealth | Notes, dishes, up to 5 photos, and visit date | No change to the data model | Grill-me |
| 4 | Row editing | Inline; pushed screens like Beli | Inline: growing notes field, dish chips, `PhotosPicker` thumbnails, date chips plus a picker | Least code, and nothing is hidden | Grill-me |
| 5 | Compare screen | Stacked + Undo; side by side; no Undo | Two stacked glass cards with the new place on top, plus Undo | Long names fit, and a mis-tap can be undone | Grill-me |
| 6 | Revisits | Re-compare only on a change or opt-in; always; never | The current category and bucket are preselected, with a Re-rank toggle (off). With no change and the toggle off, Rank only adds a visit | Places you return to often don't need to be re-compared every time | Grill-me |
| 7 | `+` in Feed and My Lists | Place picker; jump to Search; none | None for now | Keeps scope down | Grill-me |
| 8 | Feed contents | Friends + you; friends only; only you | About 6 sample friends plus you, newest first | Your new ratings show up right away, which makes them easy to check | Grill-me |
| 9 | Feed cell | Beli without the social row; with likes; compact | Avatar, "**Name** ranked/revisited **Place**", category · area, score badge, photos, notes, dishes, date, and a Rank button. Tapping the cell pushes the Place screen | Likes and comments are out of scope for v1 | Grill-me |
| 10 | Sample media | Initials, no photos; your photos; placeholders | Colored initials avatars. Sample visits have no photos | No licensing issues. Your own picked photos still exercise the photo strip | Grill-me |
| 11 | Profile contents | Header, stats, chart, activity; Beli tabs; minimal | Header, Followers · Following · Ranked, a Been row that goes to My Lists (yours only), a Swift Charts score histogram, per-category counts, and Activity | The histogram shows off the bell curve | Grill-me |
| 12 | Friend profiles | Same screen read-only; local Follow; none | The same screen, read-only, opened from a Feed avatar | Follow and private accounts come with the backend | Grill-me |
| 13 | Data model | Mirror the schema and derive the feed; stored feed items | `Ranking.userID`, new `Visit` and `User` types. The feed is derived from visits: a ranking's first visit reads "ranked", later ones "revisited" | Matches the schema, and the score never goes stale | Grill-me |
| 14 | After saving | Result step; dismiss | A result step with a big score badge and "#3 of 14 in Restaurants", then Done | Ranking pays off with a visible result | Grill-me |
| 15 | Change propagation | NotificationCenter; `@Observable`; viewWillAppear | `@Observable` stores. UIKit screens read them in `updateProperties()`; SwiftUI views read them in `body` | Less glue code | Grill-me |
| 16 | Add-ons | My Lists → Place; delete visits; visit history | My Lists rows push the Place screen. This supersedes decision 14 in plan 01 | Gives a way to revisit and re-rank | Grill-me |
| 17 | Feed score | Current derived score; score when ranked | Current score | Scores are never stored (rating-system.md) | Build |
| 18 | Default category | Fixed; from the POI | Your ranking's category, otherwise the POI's mapped category, changeable with a menu | Matches Beli's "Add to my list of" dropdown | Build |
| 19 | Sample visit history | None; generated | Your sample rankings get one visit each, spread over the past 6 weeks. Friends' entries list their own visits with notes and dishes | The Feed and Activity have history from the first launch | Build |
| 20 | Screen tech | — | Feed and Profile use collection views with hosting cells. The rate flow is SwiftUI in a `NavigationStack`, presented by one shared helper | Follows the project conventions. Each entry point presents the flow the same way | Build |
| 21 | Starting tab | Search; Feed | Feed | Search is no longer the screen under development | Build |
| 22 | Store shape | Async fetch methods; observable loaded state | Stores expose `rankings`, `visits`, and `users` as properties, with async throwing mutations. Loading is added with the backend | Observation needs properties to track. A backend store keeps a cache of the same shape | Planning |
| 23 | Insertion logic | Inside the view; a pure value type | `BinaryInsertion`: a `nonisolated` struct with `low`/`high`, an answer history for Undo, and `position` when done | Unit-testable with no UI | Planning |
| 24 | Restaurants from Apple places | Empty cuisine string; optional cuisine | `Restaurant.cuisine` becomes `String?`. Apple has no cuisine, and the UI joins only the parts that exist | Avoids "Restaurant · " and " · SoHo" | Planning |
| 25 | Passing dependencies | More init parameters per screen; one bundle | `AppContext` (ranking store, user store, place store, location manager), created by `TabBarController` | Every screen can push Place and present the rate flow | Planning |
| 26 | Sample friends | Names from the reference screenshots; invented | Six invented friends with made-up handles, reusing the 38 sample places | Keeps real people's names out of the repo, and `mapItemID`s stay real | Build |
| 27 | Histogram mark | `BarMark(xStart:xEnd:y:)`; `RectangleMark` | `RectangleMark` from 0 to the count | `BarMark` with a `y` value draws a thin bar floating at that height | Build |
| 28 | Profile title | `title`; `navigationItem.title` | `navigationItem.title` | Setting `title` also renamed the Profile tab to the user's name | Build |
| 29 | Feed subtitle | `Label`; inline `Text` with an `Image` | "icon · area" as one `Text` | `Label` left a wide gap after the icon. Matches Beli | Build |
| 30 | Undo after the last answer | Undo can reach it; saves immediately | Saves immediately | The result step needs the saved ranking. Back from the compare step still cancels before that | Build |
| 31 | Details button label | Okay (Beli); Rank | Rank | Says what happens next. A revisit with Re-rank off still just adds the visit | Review |
| 32 | Skip while comparing | None (decision 7); skip one pair; stop and insert | A Skip button next to Undo that stops and inserts the place just below the current comparison, as if they tied | The user asked for it, and it's the escape hatch rating-system.md planned for. This updates app-wide decision 7 | Review |

## How the code should be written

- **Simple and succinct.** Self-documenting names, with comments only for the *why*. No
  third-party dependencies, though Swift Charts and PhotosUI are system frameworks. Follow the
  Schreiber style and CLAUDE.md conventions (`configViewController()` / `configCollectionView()` /
  `configDataSource()`, Xcode headers dated 11/26/26, blank-line rule).
- **The user's Swift background is newer than plan 01 says.** They learned from Stanford CS193p
  (2020, SwiftUI), Sean Allen's iOS Dev Job Interview Practice (late 2022), and Hacking with
  Swift+ (2022). They know SwiftUI and UIKit up to about iOS 16, including diffable data sources,
  `UIHostingConfiguration`, and `PhotosPicker`. Concepts after 2022 still get a short explanation
  in the summary at the end: the Observation framework (`@Observable`), UIKit's automatic
  observation tracking and `updateProperties()`, Swift 6 concurrency (`MainActor` default
  isolation, `nonisolated`, and `Sendable`), Liquid Glass modifiers, and `Transferable` loading
  from `PhotosPickerItem`.
- Check the UI in the simulator, not previews, and keep it running. Don't commit until the user
  says to.

## Steps

### 1. Models — `app/Tummy/Models/`

- `User.swift` (new): `id`, `name`, `handle`, `memberSince`, `initials`, and a stable
  `avatarColor` (hashed like `SampleData.communityScore`). `Follow` has `followerID` and
  `followeeID`.
- `Ranking`: add `userID`. `Restaurant.cuisine` becomes `String?`, and a new
  `Restaurant(place:)` sets the neighborhood to `place.city`.
- `Visit.swift` (new): `id`, `rankingID`, `date`, `createdAt`, `notes`, `dishes: [String]`, and
  `photos: [Data]`. `dayText` shows Today, Yesterday, a weekday within a week, or "November 8".
- `FeedItem.swift` (new): `user`, `ranking: ScoredRanking`, `visit`, and `isFirstVisit`.
  `static func items(rankings:visits:users:showing userIDs:)` builds it newest first, by
  `date` then `createdAt`.
- `ScoreCurve.ListKey`: add `userID`, so every user's lists are scored separately.
- `PlaceSummary.kind` and `RankingCellView`: join only the parts that exist.

### 2. Rate logic — `app/Tummy/Scoring/BinaryInsertion.swift` (new)

```swift
nonisolated struct BinaryInsertion {
    private(set) var low = 0, high: Int          // window over positions (0 = worst)
    private var history: [(Int, Int)] = []
    var isDone: Bool { low == high }
    var midpoint: Int { (low + high) / 2 }
    var position: Int { low }                     // valid once isDone
    var canUndo: Bool { !history.isEmpty }
    mutating func answer(newIsBetter: Bool)      // low = mid + 1 or high = mid
    mutating func undo()
}
```

### 3. Stores — `app/Tummy/Stores/`

- `RankingStore`: `protocol RankingStore: AnyObject, Observable` with `var rankings`,
  `var visits`, and these async throwing methods:
  - `rank(_ restaurant:, category:, bucket:, at position:, by userID:, visit:) -> Ranking`
    removes your existing ranking of that place (closing its gap), shifts positions at or above
    `position`, and inserts. It reuses the old ranking ID so earlier visits stay attached.
  - `addVisit(_:)`
  - `delete(_:)`, which now also drops that ranking's visits
- `SampleRankingStore` becomes `@Observable` and is seeded from `SampleData`.
- `UserStore.swift` (new): `protocol UserStore: AnyObject, Observable` with `currentUser`,
  `users`, `follows`, `followers(of:)`, and `following(of:)`, plus `SampleUserStore`.
- `AppContext.swift` (new): a struct holding the three stores and one `CLLocationManager`.

### 4. Sample data — `app/Tummy/SampleData/`

- `sample_users.json` (new): you plus 6 friends, and the follows (you follow all of them; most
  follow you back).
- `sample_rankings.json`: every entry gains a `user` handle. Your 38 entries stay as they are.
  Add about 6–10 entries per friend, reusing the existing 38 places so `mapItemID`s are real.
  Friend entries carry `visits: [{ daysAgo, notes?, dishes? }]`, and a few have two visits to
  show "revisited".
- `SampleData.swift`: decode users, follows, and visits. Give each `mapItemID` one `Restaurant`
  ID across users. Generate one visit per entry that has no `visits`.

### 5. Rate flow — `app/Tummy/Views/Rate/` (new folder)

- `RateFlowModel` (`@Observable`): the place, the existing ranking, the draft (category, bucket,
  re-rank, notes, dishes, photos, date), the comparison candidates (your rankings in that list
  without this place, worst first), the `BinaryInsertion`, and `save()`. Rank does one of:
  - No change and re-rank off: `addVisit`, then show the result.
  - An empty list: rank at position 0.
  - Otherwise: push the compare step.
- `RateFlowView`: a `NavigationStack` with a path over `.compare` and `.result`.
- `RateDetailsView`: a header with the name, kind, and close button, then the category menu, the
  three bucket circles ("How was it?"), the Re-rank toggle (ranked places only), and these rows:
  - Notes: a growing `TextField(axis: .vertical)`.
  - Dishes: a field that turns entries into removable chips in a horizontal scroll.
  - Photos: `PhotosPicker` with up to 5 images, downscaled with
    `UIImage.preparingThumbnail(of:)` and stored as JPEG `Data`, shown as thumbnails.
  - Date: Today, Yesterday, and 2 days ago chips, plus a compact `DatePicker` capped at today.

  Rank is disabled until a bucket is picked.
- `CompareView`: "Which did you like more?" over two glass cards (new place on top, then the
  candidate at `midpoint`), with Undo and Skip toolbar buttons. When `isDone`, it saves and pushes
  the result.
- `RateResultView`: a large score badge, "#3 of 14 in Restaurants", and Done.
- `UIViewController+Navigation.swift` (new, in `ViewControllers/`):
  `presentRateFlow(for: PlaceSummary, context:)` (large-detent sheet) and
  `showPlace(_: PlaceSummary, context:)`, which replace `SearchViewController.rank` and
  `openPlace`.

### 6. Feed — `FeedViewController` and `Views/FeedCellView.swift`

- `FeedCellView`: the Beli-style layout from decision 9. `AvatarView` (new) shows the initials
  circle. Closures handle the avatar tap and the Rank button.
- `FeedViewController`: a large title "Feed" and a plain list. `ViewHelper.makeFeedCell(...)` takes
  the closures. `updateProperties()` reads the stores and applies a snapshot of `Visit.ID`s,
  reconfiguring kept items. Selecting a cell calls `showPlace`. The avatar pushes
  `ProfileViewController(user:)`.

### 7. Profile — `ProfileViewController` and `Views/Profile/`

- Sections are `header`, `stats`, and `activity`. Items are an enum: `.header`, `.stats`, and
  `.visit(Visit.ID)`.
- `ProfileHeaderView`: avatar, name, @handle, "Member since January 2025", and the three counts.
  On your own profile, the Been row selects the My Lists tab.
- `ProfileStatsView`: a Swift Charts `BarMark` histogram in 0.5-point bins colored by bucket,
  plus per-category counts.
- Activity reuses the feed cell for that user's visits.
- Observes the stores through `updateProperties()`, like the Feed.

### 8. Existing screens

- `TabBarController`: builds `AppContext`, uses Feed and Profile instead of the placeholders,
  and starts on Feed.
- `MyListsViewController`: reads `store.rankings` (your user only) in `updateProperties()`.
  Rows become selectable and call `showPlace`.
- `SearchMapView`: computes ranked pins from `rankingStore.rankings` in place of the
  `@State` copies, so they update after rating (this resolves plan 02's note).
- `SearchViewController` and `PlaceView` call the shared helpers.
- Delete `PlaceholderViewController` if nothing else uses it.

### 9. Tests — `app/TummyTests/`

- `BinaryInsertionTests`: the question count is ⌈log₂(n + 1)⌉, every answer sequence lands on
  the right position, and Undo restores the window.
- `RankingStoreTests`:
  - An insert shifts positions.
  - A re-rank keeps the ID and visits and leaves dense positions.
  - A delete closes the gap and drops the ranking's visits.
- `FeedItemTests`: the first visit reads "ranked", later ones "revisited"; only followed users
  and you appear; the order is newest first.
- `ScoreCurveTests`: the `makeRanking` helper gains `userID`, plus a test that two users' lists
  are scored separately.

### 10. Docs

- `docs/README.md`: the build order now says steps 3, 4, 6, and 7 are plan 03.
- `product.md`: the core loop puts details before comparisons, and the `+` button is deferred.
- `rating-system.md`: the comparison flow follows the details sheet, plus the revisit rule.
- `architecture.md`: the observable store shape, `UserStore`, and `AppContext`.
- `decisions.md`: add decision 22, observable stores observed through `updateProperties()` and
  SwiftUI.
- Plan 01, decision 14: mark it as superseded by plan 03.

## Verification

- `xcodebuild test -project app/Tummy.xcodeproj -scheme Tummy -destination 'platform=iOS
  Simulator,name=iPhone 18 Pro' -derivedDataPath tmp/DerivedData`. All tests pass.
- In the simulator, with the location set to lower Manhattan:
  - **New place.** Pick an unranked pin and tap Rank. Pick a bucket, add notes, a dish, 2
    photos, and Yesterday. Answer the comparisons, using Undo once. The result shows the score
    and rank. The Feed's top item shows the photos, the pin now has a checkmark, and My Lists
    and the Profile histogram include it.
  - **Revisit.** Rate a ranked place with re-rank off, then check the Feed shows "revisited" and
    the score is unchanged.
  - **Re-rank.** Change the bucket of a ranked place, then check it moved in My Lists with no
    duplicate.
  - **Feed navigation.** A Feed cell pushes the Place screen. An avatar pushes the friend's
    read-only Profile. Its Rank button opens the flow.
  - **Profile.** Your Been row switches to My Lists. A My Lists row pushes the Place screen.
  - **Delete.** Deleting in My Lists removes that place's Feed items.
  - **Dark mode and large text** look right on Feed, Profile, and the rate sheet.

## Out of scope

The `+` place picker, companions, labels, stealth mode, likes, comments and share, Follow and
private accounts, follower lists, visit history on the Place screen, deleting or editing visits,
streaks, challenges, global rank, Guides, and want-to-try.

## Implementation notes

- Sample data is in memory, so every launch starts fresh from the JSON files.
- In the simulator, very short synthetic taps don't flip the glass `Toggle`. A normal press works.
- Your own visits read "Arvind Kasiliya ranked …" in the Feed. Beli says "You". A small follow-up.
- `ProfileViewController.Item` is `nonisolated`, because diffable data sources hash identifiers off
  the main actor.
- Photos are kept as JPEG `Data` on each `Visit` (downscaled to fit 1600 points), and each cell
  decodes them on display. A thumbnail cache belongs with the backend's photo storage.
