# Tummy docs

Tummy is an iOS social app for ranking restaurants with friends. It is modeled on Beli, with one
key difference: scores within each bucket follow a bell curve instead of being spread evenly, so
most places land around 7.5–8.5 and a 10 is genuinely rare.

| Doc | What's in it |
| --- | --- |
| [product.md](product.md) | Features, navigation, social model, and what's out of scope |
| [rating-system.md](rating-system.md) | Buckets, the comparison flow, and the bell-curve score math |
| [architecture.md](architecture.md) | Repo layout, iOS client architecture, backend, and data model |
| [decisions.md](decisions.md) | Major architectural and app-wide decisions and the reasoning behind each |
| [plans/](plans/) | Step-by-step build plans, one per UI piece, each with a decision matrix for that feature |

## Build order

The app is built one UI component at a time against static sample data, so each piece can be
debugged in isolation before any backend exists.

1. **My Lists + score engine** — [plans/01-my-list.md](plans/01-my-list.md)
2. **Search tab (full-screen map) + a minimal Restaurant detail screen** —
   [plans/02-search-map.md](plans/02-search-map.md). Built before the rate flow, so the map can
   start it.
3. **Rate flow (details sheet → comparisons → result), Feed, and Profile** —
   [plans/03-feed-profile-rating.md](plans/03-feed-profile-rating.md). One plan covering what used
   to be steps 3, 4, 6, and 7, since the Feed and Profile show what the rate flow creates.
4. Restaurant detail (the rest: photos, all scores, ratings breakdown, and visit history)
5. Supabase backend (auth, Postgres, storage) replaces the sample repositories
6. Social graph: people search, follow and unfollow, follower lists, and private accounts with
   follow requests
7. Settings and App Store readiness: a Settings screen (private account, sign out, and account
   deletion), editing and deleting visits and rankings, reporting posts and blocking users, the app
   icon, launch screen, and privacy manifest
8. Import from Beli: rankings from a CSV or JSON file (see
   [product.md](product.md#importing-from-beli))

Steps 1–8 make the MVP, which ships to friends through TestFlight.
