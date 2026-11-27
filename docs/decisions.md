# App-wide decisions

Major architectural and app-wide decisions. Decisions that only affect one feature live in that
feature's plan in [plans/](plans/), in its **Decision matrix** section. Add new entries at the
bottom, and mark any that are later reversed instead of deleting them.

| # | Decision | Why |
| --- | --- | --- |
| 1 | Ranked order is the source of truth, and scores come from rank through a truncated-normal curve per bucket | Gives more 7.5–8.5s than 10s, which is the app's core difference from Beli |
| 2 | Buckets: like 6.5–10, fine 4–6.5, dislike 0–4, σ = range / 4 | People mostly log places they liked. Constants are kept in one place for tuning |
| 3 | Five categories (Restaurants, Bars, Bakeries, Cafes, Dessert), each its own ranked list with its own buckets and curve | Matches Beli. Cross-category comparisons are meaningless. Shorter names than Beli's "Coffee & Tea" and "Ice Cream & Dessert" |
| 4 | Rank places only; dishes are tags on visits | Keeps the data model and comparisons small for v1 |
| 5 | One ranking per user per place; revisits add visits and can re-rank | No duplicates in the list, and history is kept |
| 6 | Visit fields: date, notes, dish tags, and up to 5 photos | Rich enough to be social without being heavy |
| 7 | Comparison uses binary insertion with forced choice and no tie button. **Updated by plan 03:** a Skip button stops and inserts at the current comparison | Matches Beli's behavior. Skip is a way out when two places feel equal |
| 8 | Apple MapKit for place search and data | Free, no API key, native. Our own UUIDs plus Apple's place ID for de-duplication |
| 9 | Public by default, with an optional private account that requires approved follows | Beli-like discovery while still allowing privacy |
| 10 | Four tabs (Feed, My Lists, Search, Profile) plus a modal rate flow | Rating is an action, not a destination |
| 11 | Search tab is a full-screen map with a bottom-pinned search bar and a results sheet | Lets people explore by map and rate straight from a pin |
| 12 | Backend v1 is Supabase direct with RLS; the long term is our own API in `services/` | Quickest way to share with friends. Store protocols make the switch cheap |
| 13 | No Realm | MongoDB deprecated Atlas Device Sync in 2024, and the SDK is only community-maintained |
| 14 | Offline caching is deferred (GRDB is the leading candidate) | Not needed to debug the UI or share with friends |
| 15 | Monorepo: `app/`, `docs/`, `supabase/`, `services/` | Only one client is planned, so no `apps/ios` nesting |
| 16 | Single app target plus a test target, Swift 6 mode, default MainActor isolation | Simple. Extract a package only if needed |
| 17 | Unit tests live in `app/TummyTests` (Swift Testing), run through a shared `Tummy` scheme | Xcode's `<Target>Tests` convention. Auto-generated schemes have no test action |
| 18 | UIKit shell, collection-view lists, SwiftUI cells and simple controls or screens (Schreiber style) | SwiftUI for speed of building; UIKit where list performance matters |
| 19 | Screens get data from `*Store` protocols (e.g., `RankingStore`) with sample implementations first | Swap sample data, Supabase, and our own API without touching UI code |
| 20 | Build one UI piece at a time against static sample data, each with its own plan | Each part is debuggable in isolation |
| 21 | The category type is `PlaceCategory`, not `Category` | Foundation exposes an Objective-C `Category` type, which makes the name ambiguous |
| 22 | Stores are `Observable` classes exposing loaded data as properties. UIKit screens read them in `updateProperties()`, SwiftUI views in `body` | Every tab updates after a change with no notification glue. A backend store keeps a cache of the same shape |
| 23 | iPhone only (`TARGETED_DEVICE_FAMILY` = 1), no iPad layout | On Apple silicon Macs the app runs as "Designed for iPhone" in a phone-sized window instead of stretching to an iPad layout. An iPad layout can come later |
| 24 | Import Beli rankings only from a user-supplied file. Tummy never takes Beli credentials or calls Beli's private API | Beli has no public API or export, and its terms ban scraping and reverse engineering. Calling it could cost users their Beli accounts, risk App Store review, and break without warning. A US data request isn't guaranteed (its privacy policy promises a copy only in the EEA and UK) |
