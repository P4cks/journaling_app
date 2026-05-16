/// What a single layout/entry section contains.
///
/// - [text] — a single full-width multi-line text region. Renders as a
///   plain `TextField` (no `BlockCard`). Backed by exactly one
///   `JournalBlockData` of type `BlockType.textBlock` so the existing
///   `TextBlockContent` JSON and `BlockSettings.textCharLimit` carry
///   over.
/// - [blockGrid] — a 2-column staggered grid of 1×1 blocks. The number
///   of rows is configurable (1..4 in the editor); slots = 2 * rows.
///
/// Append-only. New values **must** be added at the end — Hive
/// serialises enums by index, so reordering would corrupt persisted
/// data.
enum SectionKind { text, blockGrid }
