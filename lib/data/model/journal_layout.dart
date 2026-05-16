import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/layout_section.dart';

class JournalLayout {
  final String id;
  final String name;
  final LayoutKind kind;
  final List<LayoutSection> sections;
  final String? iconName;

  const JournalLayout({
    required this.id,
    required this.name,
    required this.kind,
    required this.sections,
    this.iconName,
  });

  /// `copyWith` with explicit-null support for `iconName`: pass
  /// `clearIcon: true` to set the icon back to `null` so the layout falls
  /// back to the default icon.
  JournalLayout copyWith({
    String? id,
    String? name,
    LayoutKind? kind,
    List<LayoutSection>? sections,
    String? iconName,
    bool clearIcon = false,
  }) => JournalLayout(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    sections: sections ?? this.sections,
    iconName: clearIcon ? null : (iconName ?? this.iconName),
  );

  @override
  String toString() =>
      'JournalLayout(id: $id, name: $name, kind: $kind, icon: $iconName, sections: ${sections.length})';
}
