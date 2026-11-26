# Tummy

iOS social app for ranking restaurants with bell-curve scores. Monorepo:

- `app/` — iOS app (Xcode project, Swift 6, default MainActor isolation)
- `docs/` — design docs. Read `docs/README.md` first. App-wide decisions are in
  `docs/decisions.md`; build plans live in `docs/plans/`.
- `supabase/`, `services/` — backend (not built yet)

## Conventions

- Programmatic UIKit shell with no storyboards. Long lists use `UICollectionView` with diffable
  data sources and `UIHostingConfiguration` SwiftUI cells. Simple screens can be SwiftUI.
- View controllers use `configViewController()`, `configCollectionView()`, and
  `configDataSource()` from `viewDidLoad()`.
- Screens get data only through store protocols (e.g., `RankingStore`). Sample (in-memory)
  implementations come first.
- New Swift files keep Xcode's header, including `Created by Arvind on <M/D/YY>.`
- Swift formatting: if a type's body starts with a blank line after its declaration, end it with
  a blank line before the closing brace too.
- Scores are always derived from rank through `ScoreCurve`. Never store a user-entered score.
- Every feature plan in `docs/plans/` has a **Decision matrix** (decision, options considered,
  chosen, why, and whether it came from grill-me, review, or building). Record feature-specific
  decisions and the user's later changes there. Only major architectural or app-wide decisions
  go in `docs/decisions.md`. When either changes, also update the relevant doc.
- Each plan in `docs/plans/` is built on its own `feature/<name>` branch, created before any code
  changes. Branch from the previous feature's branch until it's merged into `main`.

## Building

- Build and test: `xcodebuild test -project app/Tummy.xcodeproj -scheme Tummy -destination
  'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath tmp/DerivedData`
- Keep code simple and succinct, and explain any newer Swift concept used when summarizing work.
