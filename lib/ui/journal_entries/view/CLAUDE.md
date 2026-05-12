# lib/ui/journal_entries/view — Entries list screen widget

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [journal_entries_screen.dart](journal_entries_screen.dart) — public
  `JournalEntriesScreen` + private `_SectionedList`, `_MonthHeader`,
  `_EmptyState`.

## Composition

```
Scaffold
└── AppBar("Entries")
└── body: vm.isEmpty
          ? _EmptyState
          : _SectionedList(sections)

_SectionedList
└── CustomScrollView
    └── for each MonthSection:
        ├── SliverToBoxAdapter(_MonthHeader)
        └── SliverList.builder(EntryListTile)
    └── SliverToBoxAdapter(SizedBox(height: 24))   // trailing safe-area
```

`EntryListTile` lives in [../widgets/](../widgets/CLAUDE.md).

## Gotchas

- **`SliverList.builder` over a `List`, not a stream.** All entries
  are in memory; this scales fine for personal-journal-sized data.
- **Tap → `context.push`, not `context.go`.** Keeps the editor on the
  entries-tab navigation stack so back returns here, not Home.

## When to update this file

- The list gets new affordances (filter, search bar in AppBar).
- The empty state changes.
