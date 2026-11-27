# Architecture

## Repo layout (monorepo)

```
tummy/
├── app/                  iOS app (Xcode project, single target + unit tests)
│   ├── Tummy.xcodeproj
│   ├── Tummy/
│   └── TummyTests/
├── docs/                 Design docs and build plans
├── supabase/             Migrations, seed data, edge functions (later)
└── services/             Our own backend services (later; e.g., the API)
```

There's only one client, so it lives in `app/` rather than `apps/ios/`. The models and score
engine stay in the app target for now. Move them into a Swift package only if test speed or reuse
calls for it.

## iOS client

### Platform and language

- iOS 27.2 deployment target, Xcode 27.
- Swift 6 language mode, default actor isolation `MainActor`, approachable concurrency.
- Pure logic (the score engine and models) is `nonisolated` with `Sendable` value types so it can
  be tested and used off the main actor.

### UI approach

Code style follows `~/Development/Archive/Schreiber`:

- **Programmatic UIKit shell** with no storyboards. `SceneDelegate` builds the root
  `UITabBarController`, which holds one `UINavigationController` per tab.
- **View controllers** follow a `configViewController()`, `configCollectionView()`,
  `configDataSource()` sequence called from `viewDidLoad()`.
- **Lists** are always `UICollectionView` with a compositional list layout and a
  `UICollectionViewDiffableDataSource`. Never use SwiftUI `List` for long or intensive lists.
- **Cell content** is SwiftUI, rendered with `UIHostingConfiguration` inside
  `UICollectionView.CellRegistration`. Registration factories live in a `ViewHelper` enum.
- **Simple or static screens** (settings, forms, small sheets) can be pure SwiftUI hosted in a
  `UIHostingController`.
- **Previews**: every view gets a `#Preview`. Since Xcode 15 the macro takes a UIKit `UIView` or
  `UIViewController` directly, so no wrapper types are needed.

### Data access

Screens never talk to a backend directly. Each domain gets a store protocol. Stores are
`Observable` classes that expose their loaded data as properties and change it through async
methods:

```swift
protocol RankingStore: AnyObject, Observable {
    var rankings: [Ranking] { get }   // every user's
    var visits: [Visit] { get }
    func rank(_:category:bucket:at:by:visit:) async throws -> Ranking
    func addVisit(_ visit: Visit) async throws
    func delete(_ id: Ranking.ID) async throws
}
```

UIKit screens read stores in `updateProperties()` and SwiftUI views read them in `body`, so both
redraw when the data changes. `UserStore` holds users and follows. `TabBarController` creates
one `AppContext` (the ranking, user, and place stores plus a location manager) and passes it to
every tab, so a change in one tab shows in the others. Feed items aren't stored: `FeedItem` builds
them from visits, and a ranking's first visit reads "ranked".

- **Now**: `SampleRankingStore` and `SampleUserStore` keep data in memory, loaded from bundled
  JSON.
- **Soon**: `SupabaseRankingStore` built on `supabase-swift`.
- **Later**: an implementation that calls our own API in `services/api`, with no screen changes.

Places on the map come from Apple Maps through `PlaceStore`, whose only implementation is
`MapKitPlaceStore`. A `Place` is keyed by Apple's map item ID, and `Restaurant.mapItemID` links a
ranking to it. That's the same key as `restaurants.apple_place_id` below. Until the backend has
real averages, `SampleData.communityScore(for:)` makes up each place's community score.

Offline storage and caching are deferred. When they're added, GRDB (SQLite) is the leading
candidate because its tables mirror the Postgres schema.

## Backend

**Phase 1, sharing with friends: Supabase direct.**

- **Auth**: Supabase Auth with Sign in with Apple.
- **Database**: Postgres, with Row Level Security enforcing private-account visibility.
- **Photos**: Supabase Storage (S3-compatible). Downscale and compress on device before upload.
- Multi-step logic (inserting a ranking and shifting positions) runs in SQL functions called over
  RPC, so the invariants live on the server.

**Phase 2, own the API:** a service in `services/api` sits in front of Postgres. The app switches
store implementations. Supabase can stay as the hosted Postgres, Auth, and Storage provider.

## Data model (draft)

```
profiles      id (= auth uid), username unique, display_name, avatar_path, is_private, created_at
follows       follower_id, followee_id, status ('pending' | 'accepted'), created_at
              PK (follower_id, followee_id)
restaurants   id uuid, apple_place_id unique null, name, address, latitude, longitude,
              cuisine, neighborhood, created_at
rankings      id uuid, user_id, restaurant_id,
              category ('restaurant' | 'bar' | 'bakery' | 'cafe' | 'dessert'),
              bucket ('like' | 'fine' | 'dislike'), position int, created_at, updated_at
              UNIQUE (user_id, restaurant_id), UNIQUE (user_id, category, bucket, position)
visits        id uuid, ranking_id, visited_on date, notes text, dishes text[], created_at
visit_photos  id uuid, visit_id, storage_path, sort_order, width, height
```

Feed items are visits and new rankings from accounts the viewer follows, which RLS filters
through `follows` and `is_private`.
