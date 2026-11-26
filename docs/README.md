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
2. Comparison flow (binary insertion)
3. Rate modal (bucket pick → compare → notes, dishes, photos)
4. Search tab (full-screen map and results sheet)
5. Restaurant detail
6. Feed
7. Profile
8. Supabase backend (auth, Postgres, storage) replaces the sample repositories
