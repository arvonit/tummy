# Rating system

The **ranked order** is the source of truth. A user never types a score. Scores are always
derived from position, so they are recomputed whenever a place is added, moved, or removed.

Every **category** (Restaurants, Bars, Bakeries, Cafes, or Dessert) is ranked separately, and
each has its own three buckets. Everything below about "a bucket" means one bucket within one
category. The "All" view merges every category's list and sorts it by score.

## Buckets

| Bucket | Code | Score range | Center (μ) | σ (range / 4) |
| --- | --- | --- | --- | --- |
| Liked it | `.like` | 6.5 – 10 | 8.25 | 0.875 |
| It was fine | `.fine` | 4.0 – 6.5 | 5.25 | 0.625 |
| Didn't like it | `.dislike` | 0 – 4.0 | 2.0 | 1.0 |

The ranges are deliberately uneven. People mostly log places they liked, so "like" gets the widest
band. All constants live in one file (`ScoreCurve`) so they can be tuned later.

Because the bucket ranges don't overlap, sorting one category's list by score is the same as
sorting by bucket (like > fine > dislike) and then by position within the bucket.

## Score math

Within a bucket of `n` places, rank `i` counts from the **worst** place (`i = 0`) to the
**best** (`i = n - 1`).

1. **Percentile** (Hazen plotting position, so neither end is 0 or 1):
   `p = (i + 0.5) / n`
2. **Truncated normal quantile** on `[lo, hi]` with mean μ and standard deviation σ:
   ```
   a = (lo - μ) / σ        // -2 for every bucket, since σ = range / 4
   b = (hi - μ) / σ        // +2
   u = Φ(a) + p · (Φ(b) - Φ(a))
   score = μ + σ · Φ⁻¹(u)
   ```
   Φ is the standard normal CDF. Φ⁻¹ uses Acklam's rational approximation, which has a relative
   error under about 1.2e-9 and is plenty for one-decimal display.
3. **Display**: round to one decimal place.

Properties:

- One place in a bucket scores exactly μ (for example, 8.25 shown as 8.3 for "like").
- Scores cluster near μ. About 68% of an untruncated normal falls within ±σ, which is the middle
  half of the bucket.
- A perfect 10.0 is never produced. The top spot creeps toward the bucket ceiling as the bucket
  grows, which is the intended scarcity.

Worked example, "like" bucket with `n = 10`:

| Rank (best first) | p | Score |
| --- | --- | --- |
| 1 | 0.95 | ≈ 9.5 |
| 5 | 0.55 | ≈ 8.4 |
| 10 | 0.05 | ≈ 7.0 |

## Comparison flow (binary insertion)

This copies Beli's behavior: a **forced choice** with no tie button, plus a Skip escape hatch.

1. The user picks a bucket on the details sheet and taps Rank. If the bucket is empty, the new
   place goes in as the only entry.
2. Binary search over the bucket's current order. Each step shows the new place next to the
   place at the midpoint and asks "Which did you like more?"
3. The answer halves the search window. This repeats until the window is empty, so the exact
   insertion index is known. That takes about ⌈log₂(n + 1)⌉ questions (6 for a 50-place bucket).
4. Insert at that index, then recompute scores for the whole bucket.

Revisiting a ranked place preselects its category and bucket. If neither changes and the user
leaves **Re-rank** off, Rank only adds a visit. Otherwise the place is taken out of its list,
compared again, and reinserted, keeping its ranking ID so earlier visits stay attached.

The comparison has an **Undo** that steps back one answer. The last answer saves right away, so
it can't be undone.

**Skip**, next to Undo, stops the questions and inserts the new place just below the place it's
being compared with, as if they tied.

## Storage

Each ranking stores `(user_id, restaurant_id, category, bucket, position)`, where `position`
is a dense integer order within that user's category and bucket. An insert shifts the positions
after it. That costs O(n) row updates, which is fine at personal-list scale.

The `score` is derived. Whether a denormalized score column gets stored for feed queries is a
backend decision and is deferred.
