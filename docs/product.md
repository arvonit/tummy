# Product

## Core loop

1. A user visits a place and opens the rate flow.
2. They pick its category (see below) and a bucket: **Liked it**, **It was fine**, or
   **Didn't like it**, and can add the visit's notes, dishes, photos, and date on the same sheet.
3. They answer a few "Which did you like more?" comparisons against places already in that
   category's bucket, which inserts the new place into that ranked list.
4. Every place's score is derived from its position on a bell curve (see
   [rating-system.md](rating-system.md)).
5. Friends see the new ranking and its notes and photos in their feed.

## What gets ranked

Places, each in one of five **categories**, which work like Beli's:

| Category | Covers |
| --- | --- |
| Restaurants | Sit-down and casual meals |
| Bars | Cocktail, wine, and beer bars |
| Bakeries | Bread, pastries, and bagels |
| Cafes | Coffee and tea (Beli calls this "Coffee & Tea") |
| Dessert | Ice cream and sweets (Beli calls this "Ice Cream & Dessert") |

**Each category is its own ranked list.** A new bakery is only compared against other bakeries,
and its score comes from its position among bakeries. Comparing a croissant spot with a steakhouse
would be meaningless.

Each user has exactly one ranked entry per place. Dishes are free-text tags on a visit, not ranked
items. Ranking dishes is a possible future feature.

A ranked entry can have many **visits**. A visit has:

- Visit date (defaults to today)
- Notes (optional free text)
- Dish tags (optional)
- Up to 5 photos (optional)

Revisiting a place adds a visit and lets the user re-rank the existing entry. It never creates a
duplicate ranking.

## Navigation

A `UITabBarController` with four tabs:

| Tab | Contents |
| --- | --- |
| **Feed** | Recent rankings and visits from people you follow, newest first |
| **My Lists** | Your ranked places with scores. Scrolling chips filter by category (All merges every list, sorted by score) |
| **Search** | Full-screen map with a search bar pinned to the bottom (Apple Maps style). Zoom and tap restaurant pins to open or rate them, or type to get a results list in a sheet. Also finds people. |
| **Profile** | Your stats, score distribution, followers, and settings |

**Rating** is a modal flow, not a tab. It starts from a restaurant (map pin, search result, or
detail page) or from a Feed item. A `+` button in Feed and My Lists, which needs a place picker,
is deferred.

## Social model

- Beli-style: accounts are **public by default** and follows are one-way.
- A user can make their account **private**. Follows of a private account become requests that
  need approval, and only approved followers see that user's list, visits, and photos.
- The feed is reverse-chronological, built from accounts you follow.

## Restaurant data

Restaurant search and metadata come from **Apple MapKit** (`MKLocalSearch` filtered to food
points of interest). It's free, needs no API key, and is native on iOS. Our database keeps its own
`restaurants` table keyed by our own UUID and stores Apple's place identifier for de-duplication.

## Out of scope for v1

- Leaderboards, want-to-try lists, and lists of places to try
- Ranking dishes
- Android or web clients
- Offline mode (deferred; see [decisions.md](decisions.md))
- Comments and likes on feed items
