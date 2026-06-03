/// What a single layout/entry section contains.
///
/// - [text] — a single full-width multi-line text region. Renders as a
///   plain `TextField` (no `BlockCard`). Backed by exactly one
///   `JournalBlockData` of type `BlockType.textBlock` so the existing
///   `TextBlockContent` JSON path is reused.
/// - [blockGrid] — a 2-column staggered grid of 1×1 blocks. The number
///   of rows is configurable (1..4 in the editor); slots = 2 * rows.
/// - [featureBlock] — a single block rendered at 2×2 (full body width,
///   square aspect ratio). `blocks` holds exactly one template; `rows`
///   is `null`. The layout editor restricts the block type to
///   `BlockType.photoBlock` or `BlockType.memoryBlock`.
/// - [header] — a single-line heading. Backed by exactly one
///   `JournalBlockData` of type `BlockType.textBlock` (reuses the
///   `TextBlockContent` JSON path, like [text]), rendered as a large
///   bold one-liner. (GUS-6, FREE.)
/// - [divider] — a purely visual horizontal rule. Carries **no**
///   blocks; renders even with an empty `blocks` list. (GUS-7, FREE.)
///
/// Append-only. New values **must** be added at the end — Hive
/// serialises enums by index, so reordering would corrupt persisted
/// data. (`blockTextBody` and `wannado` are planned next, appended
/// after `divider` — see GUS-9 / GUS-8.)
enum SectionKind {
  text,
  blockGrid,
  featureBlock,
  header,
  divider,
}
