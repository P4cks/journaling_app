import 'dart:convert';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';

class JournalBlockData {
  final String id;
  final BlockType type;
  final String contentJson;
  final String visualsJson;

  const JournalBlockData({
    required this.id,
    required this.type,
    required this.contentJson,
    this.visualsJson = '{}',
  });

  Map<String, dynamic> get content =>
      (jsonDecode(contentJson) as Map<String, dynamic>);

  BlockVisuals get visuals => BlockVisuals.fromJson(visualsJson);

  factory JournalBlockData.create({
    required String id,
    required BlockType type,
    Map<String, dynamic> content = const {},
    BlockVisuals visuals = BlockVisuals.zero,
  }) => JournalBlockData(
    id: id,
    type: type,
    contentJson: jsonEncode(content),
    visualsJson: visuals.isZero ? '{}' : visuals.toJson(),
  );

  JournalBlockData copyWith({
    String? contentJson,
    Map<String, dynamic>? content,
    BlockVisuals? visuals,
  }) {
    assert(
      contentJson == null || content == null,
      'copyWith: pass either contentJson or content, not both',
    );
    return JournalBlockData(
      id: id,
      type: type,
      contentJson: content != null
          ? jsonEncode(content)
          : (contentJson ?? this.contentJson),
      visualsJson: visuals != null
          ? (visuals.isZero ? '{}' : visuals.toJson())
          : visualsJson,
    );
  }

  @override
  String toString() => 'JournalBlockData(id: $id, type: $type)';
}
