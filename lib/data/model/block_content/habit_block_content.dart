/// Per-block state for a `BlockType.habitTracker` instance.
///
/// `definitionId` points at a `HabitDefinition` in the `BlockSettings`
/// registry — that's where the title and icon live, shared across every
/// block that references the same id. Edits to a definition therefore
/// propagate to every existing block. When the definition is deleted the
/// widget falls back to a "deleted block" placeholder (the lookup
/// returns null).
///
/// `completed` is this entry's (this day's) cross-off state. The streak
/// is *derived* by the widget from the `completed` flags across all
/// entries that share the same `definitionId` — it is never stored.
///
/// Wire shape: `{"definitionId": "uuid", "completed": true}`.
/// `completed` is omitted when false (matches `TodoItem.toMap`).
class HabitBlockContent {
  final String? definitionId;
  final bool completed;

  const HabitBlockContent({this.definitionId, this.completed = false});

  factory HabitBlockContent.fromMap(Map<String, dynamic> map) {
    final defId = map['definitionId'] as String?;
    return HabitBlockContent(
      definitionId: defId == null || defId.isEmpty ? null : defId,
      completed: (map['completed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    if (definitionId != null) 'definitionId': definitionId,
    if (completed) 'completed': true,
  };
}
