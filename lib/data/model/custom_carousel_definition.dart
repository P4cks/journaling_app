import 'package:journaling_app_rewrite/data/model/carousel_item.dart';

/// User-defined custom carousel "type". Lives in the `BlockSettings`
/// registry; referenced by id from `BlockTemplate.configJson` (layout
/// slots) and from a per-entry `CustomCarouselBlockContent`.
///
/// Edits to a definition propagate live to every block that references
/// it. Deleting a definition leaves orphan blocks; the widget renders
/// a "deleted block" placeholder rather than vanishing the block.
///
/// Wire shape (in the `settings` Hive box, JSON list under
/// `block.customCarousel.definitions`):
/// ```json
/// {"id": "uuid", "title": "Energy", "items": [{"kind": "emoji", "value": "⚡"}]}
/// ```
class CustomCarouselDefinition {
  final String id;
  final String title;
  final List<CarouselItem> items;

  const CustomCarouselDefinition({
    required this.id,
    required this.title,
    required this.items,
  });

  CustomCarouselDefinition copyWith({String? title, List<CarouselItem>? items}) =>
      CustomCarouselDefinition(
        id: id,
        title: title ?? this.title,
        items: items ?? this.items,
      );

  factory CustomCarouselDefinition.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return CustomCarouselDefinition(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      items: rawItems is List
          ? [
              for (final raw in rawItems)
                if (raw is Map<String, dynamic>) CarouselItem.fromMap(raw),
            ]
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'items': [for (final item in items) item.toMap()],
  };

  @override
  String toString() =>
      'CustomCarouselDefinition(id=$id, title="$title", items=${items.length})';
}
