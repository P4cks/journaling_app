import 'package:journaling_app_rewrite/data/model/block_type.dart';

class JournalLayout {
  final String id;
  final String name;
  final List<BlockType> blocks;
  final String? iconName;

  const JournalLayout({
    required this.id,
    required this.name,
    required this.blocks,
    this.iconName,
  });

  /// `copyWith` with explicit-null support for `iconName`: pass
  /// `clearIcon: true` to set the icon back to `null` so the layout falls
  /// back to the default icon.
  JournalLayout copyWith({
    String? id,
    String? name,
    List<BlockType>? blocks,
    String? iconName,
    bool clearIcon = false,
  }) => JournalLayout(
    id: id ?? this.id,
    name: name ?? this.name,
    blocks: blocks ?? this.blocks,
    iconName: clearIcon ? null : (iconName ?? this.iconName),
  );

  @override
  String toString() =>
      'JournalLayout(id: $id, name: $name, icon: $iconName, blocks: $blocks)';
}
