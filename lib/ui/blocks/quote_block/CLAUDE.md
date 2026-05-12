# lib/ui/blocks/quote_block — Quote-of-the-day block widget

One `BlockType.quoteBlock` block. Renders a daily quote fetched from
[ZenQuotes](https://zenquotes.io). Content shape:
`{"quote": "...", "author": "...", "fetchedDate": "yyyy-MM-dd"}`. Typed
wrapper: [QuoteBlockContent](../../../data/model/block_content/quote_block_content.dart).

## Files

- [quote_block_widget.dart](quote_block_widget.dart) — `QuoteBlockWidget`.
  Stateful — owns the fetch-in-flight + last-failure flags.

## Fetch lifecycle

- **First build with empty content** → calls
  [QuoteService.getTodayQuote](../../../data/services/quote_service.dart),
  which checks the day-keyed cache in the `settings` Hive box and
  falls through to the ZenQuotes `/api/today` HTTP call on cache miss.
- **On success** → emits a new `JournalBlockData` via `onChanged`,
  baking the quote / author / fetched-date into the entry's content.
  Subsequent rebuilds short-circuit on the stored content. Re-opening
  the entry never refetches.
- **On failure** (HTTP error, network down, malformed JSON) → renders
  a "Couldn't fetch today's quote." italic message with a Retry button.
  Retry clears the failure flag and re-runs the fetch path.
- **All entries created on the same calendar day share the same
  quote** — that's the ZenQuotes `/api/today` contract, and our cache
  preserves it.

## Modes

The widget renders identically in `readOnly` and `editable` (it's not
user-editable). When a quote is stored, both modes show centred italic
text + the author below. When not yet fetched: loading spinner. On
failure: italic "Couldn't fetch" + Retry.

## Implementation details

- **`didChangeDependencies` triggers the fetch.** `initState` can't —
  the widget needs `AppDependencies.of(context)` for the service, and
  `InheritedWidget` lookup is unsafe before mount.
- **`_fetching` flag prevents duplicate concurrent fetches.** The
  widget can rebuild many times during the in-flight request (parent
  state changes); without the guard each rebuild kicks off a new
  request.
- **Emptiness**: a quote block with no quote stored counts as empty.
  This lets the sweep delete a past-day entry where the only "content"
  was a quote that never fetched (e.g. user was offline the whole day).

## Gotchas

- **ZenQuotes returns a JSON array, not an object.** The service reads
  `decoded[0]['q']` and `decoded[0]['a']`. If the API shape changes,
  update the service and bump the cache key prefix to invalidate stale
  cached entries.
- **Don't store `null` for the quote**; absent is the "not fetched
  yet" state and `toMap` omits the key.

## When to update this file

- The fetch source changes (different provider, different endpoint).
- A refresh button is added (currently the cache is one-and-done per
  day — no manual reroll on purpose).
- The emptiness rule changes (e.g. treat quote-fetched-but-empty as
  still empty, vs treat a successful fetch as content).
