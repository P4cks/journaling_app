/// User-defined habit "type". Lives in the `BlockSettings` registry;
/// referenced by id from `BlockTemplate.configJson` (layout slots) and
/// from a per-entry `HabitBlockContent`.
///
/// Edits to a definition propagate live to every block that references
/// it. Deleting a definition leaves orphan blocks; the widget renders a
/// "deleted block" placeholder rather than vanishing the block (existing
/// entries keep their logged checks on disk).
///
/// `iconName` is a name from the shared `kCarouselIcons` catalogue,
/// resolved at render time via `carouselIconFor`. An unknown/removed
/// name falls back to a question-mark glyph, never a crash.
///
/// Wire shape (in the `settings` Hive box, JSON list under
/// `block.habit.definitions`):
/// ```json
/// {"id": "uuid", "title": "Meditate", "iconName": "meditation"}
/// ```
class HabitDefinition {
  final String id;
  final String title;
  final String iconName;

  const HabitDefinition({
    required this.id,
    required this.title,
    required this.iconName,
  });

  HabitDefinition copyWith({String? title, String? iconName}) =>
      HabitDefinition(
        id: id,
        title: title ?? this.title,
        iconName: iconName ?? this.iconName,
      );

  factory HabitDefinition.fromMap(Map<String, dynamic> map) => HabitDefinition(
    id: (map['id'] as String?) ?? '',
    title: (map['title'] as String?) ?? '',
    iconName: (map['iconName'] as String?) ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'iconName': iconName,
  };

  @override
  String toString() =>
      'HabitDefinition(id=$id, title="$title", iconName=$iconName)';
}
