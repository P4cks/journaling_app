# lib/ — Source root

This is the Flutter source for the journaling app. The repository-root CLAUDE.md holds project-wide rules (commands, schema-bump discipline, gotchas, conventions, workflow). Read it first.

This file is a map of the source tree plus a maintenance contract for the per-directory CLAUDE.md files inside lib/. Each subdirectory has its own CLAUDE.md that summarises the code there in enough depth that an AGENTS can act without re-reading every file.

How the per-directory CLAUDE.md files are organised
Layered, top-down (same shape as the app's architecture):

lib/
├── CLAUDE.md                this file
├── main.dart                bootstrap — Hive init, DI wiring, ListenableBuilder for theme
├── data/                    model + storage + repositories (no Flutter widgets)
│   ├── model/               plain data classes (no annotations)
│   │   └── block_content/   typed wrappers over JournalBlockData.contentJson
│   ├── services/            thin Hive box wrappers + ChangeNotifier settings
│   └── repositories/        domain ops over services; ChangeNotifier
├── hive/                    @GenerateAdapters declaration + generated registrar
├── routing/                 go_router config + Routes / RouteNames constants
└── ui/
    ├── core/
    │   ├── widgets/         AppDependencies (DI InheritedWidget), AppIcon, AppScaffoldShell
    │   └── format/          date formatters (no `intl` dep)
    ├── theme/               buildAppTheme(), SurfacePalette catalogue, color_hex helpers
    ├── blocks/              BlockGrid, BlockCard, BlockWidget dispatcher
    │   ├── text_block/      TextBlockWidget
    │   └── mood_tracker/    MoodTrackerWidget
    ├── home/                Home screen (calendar + entry preview)
    ├── journal_entry/       Fullscreen entry editor (singular: one entry)
    ├── journal_entries/     Sectioned list of all entries (plural)
    ├── layouts/             Layouts list + layout editor + icon picker
    └── profile/             Profile tab + nested settings screen
Every leaf and intermediate directory under lib/ has a CLAUDE.md.

What each CLAUDE.md should cover
Every per-directory file should contain, in order:

Purpose — one paragraph: what this directory is and where it sits in the layered architecture.
Files — short bullet per file: what the class/function is, what key responsibilities it owns. Use markdown links with relative paths so AGENTSs can jump to source.
Implementation details that aren't obvious from the file names — patterns this directory uses, invariants it relies on, what calls into it from outside.
Gotchas — bugs that have already been hit here, subtle ordering requirements, things that look removable but aren't. The project-root CLAUDE.md has a "Gotchas hit during development" section — directory-level files should mirror that style for issues specific to their code.
When to update this file — what edits to source under this directory should also touch the CLAUDE.md.
Keep them dense but readable — AGENTSs are the primary audience, but a human should be able to skim one and orient in <60s.

Maintenance contract — read this before editing source
The CLAUDE.md files in this tree are documentation that ages. When they go stale they stop being useful and start actively misleading the next AGENTS. Keep them current:

When you add, remove, or rename a file, update that directory's CLAUDE.md in the same change. The Files bullet list should be exhaustive.
When you change a public-facing API (a function signature, a ChangeNotifier event, a Hive field) that other layers consume, audit every CLAUDE.md in the call graph and update the implementation- details + gotchas sections.
When you hit a bug that took >15 minutes to root-cause, write the postmortem into the nearest CLAUDE.md's Gotchas section while it's fresh. The project-root CLAUDE.md collects the cross-cutting gotchas; the directory-level file collects the local ones.
When you bump a Hive box name (per the schema-change rule in the root CLAUDE.md), update hive/CLAUDE.md and the current box name list in data/services/CLAUDE.md and the relevant model CLAUDE.md.
When you delete code, remove its entry — do not leave a stale bullet pointing at a file that no longer exists. Stale entries are worse than no entry.
Sanity check: when you finish a task, grep your changed files' directories for CLAUDE.md and re-skim each. If anything you wrote contradicts what's there, fix one of them.
The project-root CLAUDE.md owns: commands, top-level architecture, cross-cutting conventions, the running PR/session log, and the workflow-with-the-user section. Don't duplicate those into the per-directory files — link instead.

Files in this directory
main.dart — app entrypoint. Order matters:
WidgetsFlutterBinding.ensureInitialized()
Hive.initFlutter() then Hive.registerAdapters() (do not also call Hive.init('.') — root CLAUDE.md gotcha)
Open the three boxes (journalEntries_v5, journalLayouts_v4, settings)
Construct services → repositories → DebugSettings / ThemeSettings
layoutRepository.seedDefaultIfEmpty() so the very first launch has a default layout
runApp(MyApp(...))
MyApp is a StatefulWidget with WidgetsBindingObserver mixin. It sweeps empty past entries on cold start (initState) and on AppLifecycleState.resumed — covers the "user left the editor open at 23:55, walked away, midnight rolled over" case.
The body wraps AppDependencies (DI) around a ListenableBuilder(listenable: themeSettings, ...) so palette / accent / brightness changes rebuild the whole MaterialApp.router live. Both theme and darkTheme are supplied; themeMode drives the swap.
When you add a new repository or settings object, add it to AppDependencies and construct it here in the right order.
When to update this file
A new top-level directory is added under lib/ → add it to the tree diagram and create its CLAUDE.md.
The boot sequence in main.dart changes (new init step, new box, new global service).
The maintenance contract itself changes — keep this section accurate so future AGENTSs follow it.

## Tracking work in Linear

Work is tracked in Linear: workspace **GustoJournalingApp**, team prefix `GUS-` (e.g. `GUS-19`). Use the Linear MCP tools to read and update issues.

- New work goes in Linear, not in a file. `BACKLOG.md` is deprecated and frozen — do not add new items to it (it is kept only as a historical record of shipped work).
- When you start implementing an issue, move it to **In Progress**; when the branch/PR is up, move it to **In Review**; on merge (with the user's agreement), move it to **Done**.
- Reference the issue id in commit messages and PR titles so they link back, e.g. `feat: gate theming to Pro (GUS-26)`.

## Check your branch / worktree before editing

**Before making any changes, confirm you are on the intended branch and in
the intended worktree.** Run `git branch --show-current` and `git worktree
list` first. This repo uses multiple `.claude/worktrees/*` worktrees, so it
is easy to start editing files that belong to a different working tree than
the one you think you're in. We have been burned by changes landing directly
on `main` instead of a feature branch — never commit feature work to `main`.
If you find uncommitted work already sitting on `main`, create a new feature
branch, move the changes there, commit, and open a PR back to `main`.

## Backwards-compatibility policy (pre-1.0)

We are not yet 1.0. **Pre-existing users' Hive data is not load-bearing.** Removing a settings key, dropping a `BlockSettings` field, retiring a `BlockType`, or otherwise narrowing a persisted shape does **not** require a migration step or a read-fallback. Leave abandoned `settings` box keys on disk (they are harmless single strings) and stop reading them in code.

The schema-bump discipline still applies to the model boxes (`journalEntries_v*`, `journalLayouts_v*`) — those use generated Hive adapters and have to round-trip correctly. The relaxation only covers the `settings` box and behavioural defaults.

Document the rationale for any such removal in the commit that drops it, then move on.
