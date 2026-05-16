/// Top-level shape of a journal layout, picked by the user when the
/// layout is created.
///
/// - [blockOnly] — one implicit block-grid section containing 1×1 blocks
///   arranged in a 2-column staggered grid. Same UX as the original
///   layout model.
/// - [fixedFourPlusText] — locked structure: one block-grid section of
///   exactly four 1×1 slots (2 rows × 2 cols) followed by one text
///   section. The user can swap which block types fill the four slots
///   but cannot add, remove, resize, or reorder sections.
/// - [custom] — fully customisable. The user can append text sections
///   and block-grid sections (rows configurable 1..4), reorder them,
///   delete them, and resize block-grid sections.
///
/// Append-only. New values **must** be added at the end — Hive
/// serialises enums by index, so reordering would corrupt persisted
/// layouts.
enum LayoutKind { blockOnly, fixedFourPlusText, custom }
