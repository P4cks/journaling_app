import 'package:journaling_app_rewrite/data/model/block_type.dart';

class JournalLayout {
  final String id;
  final String name;
  final List<BlockType> blocks;

  const JournalLayout({
    required this.id,
    required this.name,
    required this.blocks,
  });

  JournalLayout copyWith({
    String? id,
    String? name,
    List<BlockType>? blocks,
  }) => JournalLayout(
    id: id ?? this.id,
    name: name ?? this.name,
    blocks: blocks ?? this.blocks,
  );

  @override
  String toString() =>
      'JournalLayout(id: $id, name: $name, blocks: $blocks)';
}
