# lib/ — Source root

This is the Flutter source for the journaling app. The repository-root CLAUDE.md holds project-wide rules (commands, schema-bump discipline, gotchas, conventions, workflow). Read it first.

This file is a map of the source tree plus a maintenance contract for the per-directory CLAUDE.md files inside lib/. Each subdirectory has its own CLAUDE.md that summarises the code there in enough depth that an agent can act without re-reading every file.

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
    └── profile/             Profile screen (appearance + streak + debug)
Every leaf and intermediate directory under lib/ has a CLAUDE.md.

What each CLAUDE.md should cover
Every per-directory file should contain, in order:

Purpose — one paragraph: what this directory is and where it sits in the layered architecture.
Files — short bullet per file: what the class/function is, what key responsibilities it owns. Use markdown links with relative paths so agents can jump to source.
Implementation details that aren't obvious from the file names — patterns this directory uses, invariants it relies on, what calls into it from outside.
Gotchas — bugs that have already been hit here, subtle ordering requirements, things that look removable but aren't. The project-root CLAUDE.md has a "Gotchas hit during development" section — directory-level files should mirror that style for issues specific to their code.
When to update this file — what edits to source under this directory should also touch the CLAUDE.md.
Keep them dense but readable — agents are the primary audience, but a human should be able to skim one and orient in <60s.

Maintenance contract — read this before editing source
The CLAUDE.md files in this tree are documentation that ages. When they go stale they stop being useful and start actively misleading the next agent. Keep them current:

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
The maintenance contract itself changes — keep this section accurate so future agents follow it.
