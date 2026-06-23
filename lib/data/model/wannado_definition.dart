import 'package:journaling_app_rewrite/data/model/wannado_item.dart';

/// User-defined "Wanna-do Carousel" type. Lives in the `BlockSettings`
/// registry; referenced by id from a `wannado` section's `definitionId`
/// (on `LayoutSection` / `EntrySection`).
///
/// Edits to a definition propagate live to every section that references
/// it. Deleting a definition leaves orphan sections; the widget renders
/// an empty placeholder rather than vanishing the section.
///
/// Wire shape (in the `settings` Hive box, JSON list under
/// `block.wannado.definitions`):
/// ```json
/// {"id": "uuid", "title": "Bucket list", "items": [{"id": "uuid", "text": "Hike the Camino"}]}
/// ```
class WannadoDefinition {
  final String id;
  final String title;
  final List<WannadoItem> items;

  const WannadoDefinition({
    required this.id,
    required this.title,
    required this.items,
  });

  WannadoDefinition copyWith({String? title, List<WannadoItem>? items}) =>
      WannadoDefinition(
        id: id,
        title: title ?? this.title,
        items: items ?? this.items,
      );

  factory WannadoDefinition.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return WannadoDefinition(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      items: rawItems is List
          ? [
              for (final raw in rawItems)
                if (raw is Map<String, dynamic>) WannadoItem.fromMap(raw),
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
      'WannadoDefinition(id=$id, title="$title", items=${items.length})';
}
