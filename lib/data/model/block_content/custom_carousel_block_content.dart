import 'package:journaling_app_rewrite/data/model/carousel_item.dart';

/// Per-block state for a `BlockType.customCarousel` instance.
///
/// `definitionId` points at a `CustomCarouselDefinition` in the
/// `BlockSettings` registry — that's where the title and ordered items
/// live, shared across every block that references the same id. Edits
/// to a definition therefore propagate to every existing block.
///
/// `selected` is stored **verbatim** (as a `CarouselItem`) rather than
/// as an index into the definition's item list, so reordering or
/// inserting items doesn't move an existing pick to a different value.
/// When the definition is deleted entirely the widget falls back to a
/// "deleted block" placeholder (the lookup just returns null).
///
/// Wire shape: `{"definitionId": "uuid", "selected": {"kind": "emoji", "value": "⚡"}}`.
/// Missing keys → null fields (no selection, orphan id).
class CustomCarouselBlockContent {
  final String? definitionId;
  final CarouselItem? selected;

  const CustomCarouselBlockContent({this.definitionId, this.selected});

  factory CustomCarouselBlockContent.fromMap(Map<String, dynamic> map) {
    final defId = map['definitionId'] as String?;
    final rawSelected = map['selected'];
    final selected = rawSelected is Map<String, dynamic>
        ? CarouselItem.fromMap(rawSelected)
        : null;
    return CustomCarouselBlockContent(
      definitionId: defId == null || defId.isEmpty ? null : defId,
      selected: selected,
    );
  }

  Map<String, dynamic> toMap() => {
    if (definitionId != null) 'definitionId': definitionId,
    if (selected != null) 'selected': selected!.toMap(),
  };
}
