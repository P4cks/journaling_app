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
/// - [blockTextBody] — a photo/memory block floated top-left with
///   text wrapping to its right and then full-width beneath it
///   (magazine `float: left`). Carries **two** blocks: the float
///   block (a `photoBlock` or `memoryBlock`, looked up by type) and a
///   `textBlock`. The layout template stores only the float block (0
///   or 1 template, like [featureBlock]); the `textBlock` is
///   materialized fresh (always starts empty, like [text]). (GUS-9, PRO.)
/// - [wannado] — a "wanna-do" / bucket-list section. Pure display: it
///   renders the user's **global** wanna-do list (managed in Block
///   settings, stored on `BlockSettings`) as a vertical auto-rotating
///   carousel. Carries **no** per-entry blocks (`blocks` is always
///   empty) — the list is global, not per-entry, so the section is
///   content-free and never round-trips data through the layout.
///   (GUS-8, PRO.)
///
/// Append-only. New values **must** be added at the end — Hive
/// serialises enums by index, so reordering would corrupt persisted
/// data.
enum SectionKind {
  text,
  blockGrid,
  featureBlock,
  header,
  divider,
  blockTextBody,
  wannado,
}
