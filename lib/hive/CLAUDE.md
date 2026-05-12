# lib/hive — Hive adapter generation

Generated-code surface for `hive_ce`. Touched rarely — most edits here
are a side effect of editing a model under [data/model/](../data/model/).

## Files

- [hive_adapters.dart](hive_adapters.dart) — `@GenerateAdapters([...])`
  declaration. Listed: `JournalEntry`, `JournalBlockData`, `BlockType`,
  `JournalLayout`. Has a `part 'hive_adapters.g.dart';` directive.
  **This is the only hand-edited file in this directory.**
- [hive_adapters.g.dart](hive_adapters.g.dart) — generated. Holds the
  per-class adapter implementations. **Do not edit.**
- [hive_registrar.g.dart](hive_registrar.g.dart) — generated. Provides
  the `Hive.registerAdapters()` extension that `main.dart` calls.
  **Do not edit.**

## How to add a new adapter

1. Add the model class under [data/model/](../data/model/).
2. Add an `AdapterSpec<MyClass>()` line to the list in
   [hive_adapters.dart](hive_adapters.dart).
3. Run `$FLUTTER pub run build_runner build --delete-conflicting-outputs`.
   This regenerates both `.g.dart` files.
4. If the new class is the root type of a new box, open the box in
   `main.dart` and wire a service for it under [data/services/](../data/services/).

## Schema-change protocol

When you **add, remove, rename, or retype a field** on any class in the
adapter list, existing serialized data in the box becomes incompatible
with the regenerated adapter:

1. Edit the model.
2. Run `build_runner` (as above).
3. **Bump the box name** in `main.dart` (e.g. `journalEntries_v5` →
   `journalEntries_v6`). Old boxes are orphaned on disk; harmless but
   never read again.
4. If a UI screen relied on data persisted under the old name (it
   shouldn't, but if so), surface a one-time migration before the
   first read of the new box.

The current box names are documented in [data/services/CLAUDE.md](../data/services/CLAUDE.md).
Update both files when bumping.

## Gotchas

- **`build_runner` failures are usually a stale `.g.dart` import.** Always
  pass `--delete-conflicting-outputs`.
- **Reordering fields in the model can change adapter byte layout.**
  Treat reordering as a schema change and bump the box name. The safer
  alternative: append new fields to the end of the class definition.
- **Don't register adapters manually anywhere else.** `main.dart` calls
  the generated `Hive.registerAdapters()` extension exactly once before
  any `openBox`. Adding another registration site risks ordering bugs.

## When to update this file

- A class is added to or removed from the `@GenerateAdapters` list.
- The schema-change protocol changes (e.g. we adopt a real migration
  framework instead of bumping box names).
