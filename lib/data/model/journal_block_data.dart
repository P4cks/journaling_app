import 'dart:convert';
import 'package:journaling_app_rewrite/data/model/block_type.dart';

class JournalBlockData {
  final String id;
  final BlockType type;
  final String contentJson;

  const JournalBlockData({
    required this.id,
    required this.type,
    required this.contentJson,
  });

  Map<String, dynamic> get content =>
      (jsonDecode(contentJson) as Map<String, dynamic>);

  factory JournalBlockData.create({
    required String id,
    required BlockType type,
    Map<String, dynamic> content = const {},
  }) => JournalBlockData(
    id: id,
    type: type,
    contentJson: jsonEncode(content),
  );
}
